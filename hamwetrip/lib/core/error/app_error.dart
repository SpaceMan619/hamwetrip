import 'package:flutter/foundation.dart';

/// The only error type a controller or widget is ever allowed to see.
///
/// Repositories catch platform exceptions (`FirebaseException`,
/// `FirebaseAuthException`, `SocketException`, ...) and translate them into one
/// of these. A widget must never receive a raw Firebase error, and must never
/// display a code like `PERMISSION_DENIED` to a traveller.
///
/// Sealed so a `switch` over an [AppError] is exhaustive and the compiler
/// catches any variant a screen forgot to handle.
@immutable
sealed class AppError implements Exception {
  const AppError({required this.message, this.cause});

  /// Human-readable, already safe to render directly in the UI.
  final String message;

  /// The underlying platform exception, for logging only. Never shown.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable connection, or the request timed out.
final class NetworkError extends AppError {
  const NetworkError({
    super.message =
        'You appear to be offline. Check your connection and try again.',
    super.cause,
  });
}

/// The signed-in user is not allowed to perform this action.
///
/// Usually means they are not a member of the trip, or not its organizer.
final class PermissionDeniedError extends AppError {
  const PermissionDeniedError({
    super.message = "You don't have permission to do that.",
    super.cause,
  });
}

/// The requested document does not exist, or was deleted by someone else.
final class NotFoundError extends AppError {
  const NotFoundError({
    super.message = "We couldn't find that. It may have been removed.",
    super.cause,
  });
}

/// A uniqueness constraint was violated — a duplicate join, a re-used invite
/// code, or a second vote from the same member.
final class AlreadyExistsError extends AppError {
  const AlreadyExistsError({
    super.message = 'That already exists.',
    super.cause,
  });
}

/// The caller supplied something the domain rejects — a blank trip name, a
/// split that does not sum to the total, an expired invite code.
final class InvalidInputError extends AppError {
  const InvalidInputError({
    super.message = 'Please check the details and try again.',
    super.cause,
  });
}

/// Rate limited, over quota, or the file exceeds the upload ceiling.
final class QuotaExceededError extends AppError {
  const QuotaExceededError({
    super.message = 'That limit has been reached. Try again later.',
    super.cause,
  });
}

/// Anything we did not anticipate. Always log [cause] when one of these
/// appears — a recurring UnknownError means the mapper needs a new case.
final class UnknownError extends AppError {
  const UnknownError({
    super.message = 'Something went wrong. Please try again.',
    super.cause,
  });
}

/// Authentication-specific failures, kept separate from [PermissionDeniedError]
/// because the UI response is different: sign-in problems belong on the form
/// field, permission problems belong on the screen.
final class AuthError extends AppError {
  const AuthError({required super.message, this.field, super.cause});

  /// Which form field to attach the message to, when the failure is a
  /// validation problem: `'email'`, `'password'`, or `'displayName'`.
  /// Null means the error belongs to the form as a whole.
  final String? field;
}
