import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/error/app_error.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [AuthRepository].
///
/// Talks to Firebase Auth for the account and to `users/{uid}` in Firestore
/// for the profile document sign-up also creates. Every method funnels its
/// `catch` clause through [mapFirebaseError] so no raw Firebase exception
/// escapes this class.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore);

  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// The web OAuth client Firebase created when the Google provider was
  /// enabled, taken from `android/app/google-services.json` where it appears as
  /// the `client_type: 3` entry.
  ///
  /// Android needs it to request an id token that Firebase will accept. This is
  /// a public client identifier, not a secret.
  static const _googleServerClientId =
      '402708743076-2500qdqcpfq8veaq27qcn0hh3l03v81v.apps.googleusercontent.com';

  AuthUser _toAuthUser(fb_auth.User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
    );
  }

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _toAuthUser(user);
  }

  @override
  Stream<AuthUser?> authState() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : _toAuthUser(user),
    );
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const UnknownError();
      return _toAuthUser(user);
    } catch (error) {
      throw mapFirebaseError(error, authField: 'password');
    }
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const AuthError(
        message: 'Tell us what to call you.',
        field: 'displayName',
      );
    }

    fb_auth.UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw mapFirebaseError(error, authField: 'email');
    }

    final user = credential.user;
    if (user == null) throw const UnknownError();

    try {
      final profile = AppUser(
        uid: user.uid,
        displayName: trimmedName,
        email: user.email ?? email.trim(),
      );
      final data = profile.toMap();
      // The domain model has no notion of a Firestore sentinel — the
      // server-authored timestamp is layered on here, at the boundary that is
      // allowed to know about Firestore.
      data['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set(data);
    } catch (error) {
      // The account and the profile must end up consistent: an auth account
      // with no profile behind it is unreachable by the rest of the app (see
      // UserRepository.watchUser), so undo the half of this signUp that
      // succeeded rather than leave it behind.
      try {
        await user.delete();
      } catch (_) {
        // Best-effort cleanup. The profile write's error is what the caller
        // needs to see; a failed delete here would only mask it, and the
        // orphaned account is still safely inert with no profile document.
      }
      throw mapFirebaseError(error);
    }

    return _toAuthUser(user);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    fb_auth.UserCredential credential;
    try {
      // v7 of google_sign_in requires initializing the singleton before use.
      // The server client id is the web OAuth client Firebase created when the
      // Google provider was enabled; Android needs it to mint an id token that
      // Firebase will accept.
      final google = GoogleSignIn.instance;
      await google.initialize(serverClientId: _googleServerClientId);

      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthError(
          message: 'Google did not return a usable sign-in. Please try again.',
        );
      }

      credential = await _auth.signInWithCredential(
        fb_auth.GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (error) {
      // Backing out of the account chooser is a decision, not a fault, so it
      // gets a neutral message rather than an error-shaped one.
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthError(message: 'Google sign-in was cancelled.');
      }
      throw AuthError(
        message: 'Google sign-in did not complete. Please try again.',
        cause: error,
      );
    } on AppError {
      rethrow;
    } catch (error) {
      throw mapFirebaseError(error);
    }

    final user = credential.user;
    if (user == null) throw const UnknownError();

    // First time through, this account has no profile document. Create one from
    // what Google gave us, so the member shows a real name in a trip roster
    // rather than a blank. `merge` keeps any edits a returning member has made.
    try {
      final doc = _firestore.collection('users').doc(user.uid);
      final existing = await doc.get();
      if (!existing.exists) {
        final profile = AppUser(
          uid: user.uid,
          displayName: (user.displayName ?? '').trim().isEmpty
              ? (user.email ?? 'Traveller').split('@').first
              : user.displayName!.trim(),
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
        final data = profile.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        await doc.set(data);
      }
    } catch (error) {
      // Unlike signUp, the account is not deleted here. A Google account exists
      // independently of this app, so removing it would be well beyond what a
      // failed profile write justifies. The next sign-in retries the profile.
      throw mapFirebaseError(error);
    }

    return _toAuthUser(user);
  }

  @override
  Future<void> signOut() async {
    try {
      // Firebase and Google hold separate sessions. Signing out of only Firebase
      // would leave the Google account chooser skipped on the next attempt,
      // which looks like the sign-out did not work.
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Never initialized, or the platform refused. Not a reason to block a
      // sign-out; the Firebase session below is the one that matters.
    }
    try {
      await _auth.signOut();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb_auth.FirebaseAuthException catch (error) {
      // Matches the documented contract regardless of whether the Firebase
      // console's email-enumeration protection is turned on: revealing that
      // an address has no account would leak the trip's member list.
      if (error.code == 'user-not-found') return;
      throw mapFirebaseError(error);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}
