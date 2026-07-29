import '../models/auth_user.dart';

/// Authentication contract.
///
/// Consumed by the login/sign-up screen, the profile screen, and every gated
/// route. Implementations throw [AppError] subtypes only — never a
/// `FirebaseAuthException`.
///
/// See also `docs/` in the pull request description for the agreed acceptance
/// criteria per method.
abstract interface class AuthRepository {
  /// Emits the current session immediately on subscription, then on every
  /// change. Emits null when signed out.
  ///
  /// This is the app's single source of routing truth: the shell listens to it
  /// and swaps between the auth stack and the main stack. Nothing else should
  /// decide whether a user is signed in.
  Stream<AuthUser?> authState();

  /// Synchronous read of the current session, for route guards that cannot
  /// await a stream. Null when signed out.
  AuthUser? get currentUser;

  /// Throws [AuthError] with `field` set to `'email'` or `'password'` for
  /// wrong-credential cases so the form can attach the message to the right
  /// input, and [NetworkError] when offline.
  Future<AuthUser> signIn({required String email, required String password});

  /// Creates the auth account **and** the `users/{uid}` profile document.
  ///
  /// These must end up consistent: if the profile write fails after the auth
  /// account is created, the implementation is responsible for recovering
  /// rather than leaving an account with no profile behind it.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  /// Beyond the guide's minimum four methods, but the login screen needs
  /// somewhere to send a user who cannot get in.
  ///
  /// Completes without error even when the address is unregistered — revealing
  /// which emails have accounts would leak the member list.
  Future<void> sendPasswordReset({required String email});
}
