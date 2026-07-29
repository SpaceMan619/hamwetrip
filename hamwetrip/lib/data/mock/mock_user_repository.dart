import '../../core/error/app_error.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import 'mock_backend.dart';

/// In-memory [UserRepository].
class MockUserRepository implements UserRepository {
  MockUserRepository(this._backend);

  final MockBackend _backend;

  @override
  Stream<AppUser?> watchUser(String uid) =>
      _backend.watch('watchUser', () => _backend.users[uid]);

  @override
  Future<AppUser?> getUser(String uid) async {
    await _backend.guard('getUser');
    return _backend.users[uid];
  }

  @override
  Future<List<AppUser>> getUsers(List<String> uids) async {
    await _backend.guard('getUsers');
    // Missing accounts are omitted rather than padded with nulls, matching the
    // documented contract.
    return uids
        .map((uid) => _backend.users[uid])
        .whereType<AppUser>()
        .toList(growable: false);
  }

  @override
  Future<AppUser> updateProfile({
    String? displayName,
    String? phone,
    String? photoUrl,
    bool clearPhone = false,
    bool clearPhotoUrl = false,
  }) async {
    await _backend.guard('updateProfile');
    final uid = _backend.requireUid();
    final existing = _backend.users[uid];
    if (existing == null) throw const NotFoundError();

    if (displayName != null && displayName.trim().isEmpty) {
      throw const InvalidInputError(message: 'Your name cannot be empty.');
    }

    final updated = existing.copyWith(
      displayName: displayName?.trim(),
      phone: phone,
      photoUrl: photoUrl,
      clearPhone: clearPhone,
      clearPhotoUrl: clearPhotoUrl,
    );
    _backend.users[uid] = updated;

    // The member documents denormalize the display name, so a profile edit has
    // to fan out. The real implementation does this with a Cloud Function;
    // doing it here keeps the mock honest about the fan-out existing.
    if (displayName != null) {
      for (final entry in _backend.members.entries) {
        final member = entry.value[uid];
        if (member != null) {
          entry.value[uid] = member.copyWith(displayName: updated.displayName);
        }
      }
    }

    _backend.emitChange();
    return updated;
  }

  @override
  Future<void> updateNotificationPrefs({required bool enabled}) async {
    await _backend.guard('updateNotificationPrefs');
    final uid = _backend.requireUid();
    final existing = _backend.users[uid];
    if (existing == null) throw const NotFoundError();

    _backend.users[uid] = existing.copyWith(notificationsEnabled: enabled);
    _backend.emitChange();
  }
}
