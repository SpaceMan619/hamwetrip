import '../../core/error/app_error.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'mock_backend.dart';

/// In-memory [AuthRepository].
///
/// Seeded accounts all use the password `hamwe1234`.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._backend);

  final MockBackend _backend;

  AuthUser? _toAuthUser(String? uid) {
    if (uid == null) return null;
    final user = _backend.users[uid];
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email, emailVerified: true);
  }

  @override
  AuthUser? get currentUser => _toAuthUser(_backend.signedInUid);

  @override
  Stream<AuthUser?> authState() =>
      _backend.watch('authState', () => _toAuthUser(_backend.signedInUid));

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    await _backend.guard('signIn');

    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw const AuthError(
        message: 'Enter a valid email address.',
        field: 'email',
      );
    }

    AppUser? match;
    for (final user in _backend.users.values) {
      if (user.email.toLowerCase() == normalized) {
        match = user;
        break;
      }
    }

    // Deliberately the same message for "no such account" and "wrong
    // password". Distinguishing them tells an attacker which addresses are
    // registered, which for a small trip app is the member list.
    const rejection = AuthError(
      message: 'That email and password combination did not work.',
      field: 'password',
    );

    if (match == null) throw rejection;
    if (_backend.passwords[match.uid] != password) throw rejection;

    _backend.signedInUid = match.uid;
    _backend.emitChange();
    return _toAuthUser(match.uid)!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _backend.guard('signUp');

    final normalized = email.trim().toLowerCase();
    if (displayName.trim().isEmpty) {
      throw const AuthError(
        message: 'Tell us what to call you.',
        field: 'displayName',
      );
    }
    if (!normalized.contains('@')) {
      throw const AuthError(
        message: 'Enter a valid email address.',
        field: 'email',
      );
    }
    if (password.length < 6) {
      throw const AuthError(
        message: 'Use at least 6 characters.',
        field: 'password',
      );
    }
    final taken = _backend.users.values.any(
      (user) => user.email.toLowerCase() == normalized,
    );
    if (taken) {
      throw const AuthError(
        message: 'That email is already registered. Try signing in.',
        field: 'email',
      );
    }

    final uid = _backend.nextId('u');
    _backend.users[uid] = AppUser(
      uid: uid,
      displayName: displayName.trim(),
      email: normalized,
      createdAt: DateTime.now().toUtc(),
    );
    _backend.passwords[uid] = password;
    _backend.signedInUid = uid;
    _backend.emitChange();
    return _toAuthUser(uid)!;
  }

  @override
  Future<void> signOut() async {
    await _backend.guard('signOut');
    _backend.signedInUid = null;
    _backend.emitChange();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await _backend.guard('sendPasswordReset');
    // Completes regardless of whether the address exists, matching the real
    // implementation's contract.
  }
}
