import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/app_error.dart';

/// Translates a platform exception into the one [AppError] a controller or
/// widget is allowed to see.
///
/// Every Firebase repository method funnels its `catch` clause through this,
/// so no `FirebaseException`/`FirebaseAuthException` ever escapes the data
/// layer. [authField] lets a caller that already knows which form field a
/// failure belongs to (e.g. sign-in's email/password split) attach it to a
/// [AuthError] the mapper produced without one.
AppError mapFirebaseError(Object error, {String? authField}) {
  if (error is AppError) return error;

  if (error is FirebaseAuthException) {
    return _mapAuthError(error, fallbackField: authField);
  }
  if (error is FirebaseException) {
    return _mapFirestoreError(error);
  }
  if (error is SocketException || error is TimeoutException) {
    return NetworkError(cause: error);
  }
  return UnknownError(cause: error);
}

AppError _mapAuthError(FirebaseAuthException error, {String? fallbackField}) {
  switch (error.code) {
    case 'invalid-email':
      return const AuthError(
        message: 'Enter a valid email address.',
        field: 'email',
      );

    // Both the legacy separate codes and the unified code Firebase Auth now
    // returns for "credential enumeration protection" map to one message —
    // distinguishing "no such account" from "wrong password" would leak
    // which emails are registered, exactly as the mocks document.
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return const AuthError(
        message: 'That email and password combination did not work.',
        field: 'password',
      );

    case 'user-disabled':
      return const AuthError(
        message: 'This account has been disabled. Contact support.',
        field: 'email',
      );

    case 'email-already-in-use':
      return const AuthError(
        message: 'That email is already registered. Try signing in.',
        field: 'email',
      );

    case 'weak-password':
      return const AuthError(
        message: 'Use at least 6 characters.',
        field: 'password',
      );

    case 'too-many-requests':
      return const AuthError(
        message: 'Too many attempts. Please wait a moment and try again.',
      );

    case 'network-request-failed':
      return NetworkError(cause: error);

    default:
      return AuthError(
        message: 'Something went wrong. Please try again.',
        field: fallbackField,
        cause: error,
      );
  }
}

/// Applied to every Firestore stream a repository exposes, so a permission
/// change or a dropped connection mid-subscription reaches the widget as an
/// [AppError] stream event instead of a raw [FirebaseException].
extension MapFirebaseStreamErrors<T> on Stream<T> {
  Stream<T> mapFirebaseErrors() {
    return handleError((Object error, StackTrace stackTrace) {
      throw mapFirebaseError(error);
    });
  }
}

AppError _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return PermissionDeniedError(cause: error);
    case 'not-found':
      return NotFoundError(cause: error);
    case 'already-exists':
      return AlreadyExistsError(cause: error);
    case 'resource-exhausted':
      return QuotaExceededError(cause: error);
    case 'unauthenticated':
      return PermissionDeniedError(cause: error);
    case 'invalid-argument':
    case 'failed-precondition':
      return InvalidInputError(cause: error);
    case 'unavailable':
    case 'deadline-exceeded':
    case 'cancelled':
      return NetworkError(cause: error);
    default:
      return UnknownError(cause: error);
  }
}
