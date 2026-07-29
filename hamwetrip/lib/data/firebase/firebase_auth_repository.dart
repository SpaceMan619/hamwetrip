import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

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
    return _auth.authStateChanges().map((user) => user == null ? null : _toAuthUser(user));
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
  Future<void> signOut() async {
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
