import '../models/app_user.dart';

/// Profile contract for `users/{uid}`.
///
/// Separate from [AuthRepository] because the two have different lifetimes and
/// different permissions: the auth account is managed by Firebase, the profile
/// document is ordinary data the user owns and edits.
abstract interface class UserRepository {
  /// Emits the profile immediately, then on every change.
  ///
  /// Emits null when the document does not exist — which is a real state, not
  /// an error: it happens in the window between account creation and profile
  /// creation, and for any account whose profile write failed. The profile
  /// screen must handle it rather than assuming a signed-in user has a profile.
  Stream<AppUser?> watchUser(String uid);

  /// One-shot read, for places that need a name without holding a subscription.
  Future<AppUser?> getUser(String uid);

  /// Batch read for rendering lists of people.
  ///
  /// Callers must not assume the result is the same length as [uids] or in the
  /// same order — deleted accounts are simply absent.
  Future<List<AppUser>> getUsers(List<String> uids);

  /// Updates only the fields supplied. Omitted parameters are left untouched.
  ///
  /// Passing [clearPhone] or [clearPhotoUrl] removes the field, which a null
  /// argument cannot express — null means "don't change this".
  Future<AppUser> updateProfile({
    String? displayName,
    String? phone,
    String? photoUrl,
    bool clearPhone,
    bool clearPhotoUrl,
  });

  /// Master push-notification switch, honoured by the FCM send triggers.
  Future<void> updateNotificationPrefs({required bool enabled});
}
