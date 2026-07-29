import 'package:flutter/foundation.dart';

/// The authentication identity, as distinct from the profile document.
///
/// [AppUser] is `users/{uid}` — a Firestore document the user can edit.
/// [AuthUser] is the Firebase Auth account, which they cannot. Keeping them
/// separate matters at sign-up: the auth account is created first, and there is
/// a window where an [AuthUser] exists with no [AppUser] behind it. Code that
/// conflates the two treats that window as corruption instead of as a state to
/// recover from.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.emailVerified = false,
  });

  final String uid;
  final String email;
  final bool emailVerified;

  @override
  bool operator ==(Object other) {
    return other is AuthUser &&
        other.uid == uid &&
        other.email == email &&
        other.emailVerified == emailVerified;
  }

  @override
  int get hashCode => Object.hash(uid, email, emailVerified);

  @override
  String toString() => 'AuthUser($uid, $email)';
}
