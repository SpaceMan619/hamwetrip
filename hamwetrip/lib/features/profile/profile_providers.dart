import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_error.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/state/base_controller.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// Profile-screen actions: editing the profile, toggling notifications, and
/// signing out. `data` (`bool`) means "did the last action succeed" — the
/// profile's actual content comes from `currentUserProfileProvider`, which
/// updates on its own once one of these actions lands.
class ProfileActionsController extends BaseController<bool> {
  ProfileActionsController(this._userRepository, this._authRepository);

  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  Future<bool> updateProfile({
    String? displayName,
    String? phone,
    String? photoUrl,
    bool clearPhone = false,
    bool clearPhotoUrl = false,
  }) {
    return submit(() async {
      try {
        await _userRepository.updateProfile(
          displayName: displayName,
          phone: phone,
          photoUrl: photoUrl,
          clearPhone: clearPhone,
          clearPhotoUrl: clearPhotoUrl,
        );
        setData(true);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }

  Future<bool> setNotificationsEnabled(bool enabled) {
    return submit(() async {
      try {
        await _userRepository.updateNotificationPrefs(enabled: enabled);
        setData(true);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }

  Future<bool> signOut() {
    return submit(() async {
      try {
        await _authRepository.signOut();
        setData(true);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }
}

final profileActionsControllerProvider =
    StateNotifierProvider.autoDispose<
      ProfileActionsController,
      ControllerState<bool>
    >(
      (ref) => ProfileActionsController(
        ref.watch(userRepositoryProvider),
        ref.watch(authRepositoryProvider),
      ),
    );
