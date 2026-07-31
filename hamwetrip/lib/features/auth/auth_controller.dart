import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_error.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/state/base_controller.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Backs the login/sign-up screen. Not stream-backed — [authStateProvider]
/// already owns the app's routing truth — this only tracks the in-flight
/// submit and its outcome, so the form can show a spinner and an error
/// without polling anything.
class AuthController extends BaseController<AuthUser?> {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<bool> signIn({required String email, required String password}) {
    return submit(() async {
      try {
        setData(await _repository.signIn(email: email, password: password));
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return submit(() async {
      try {
        setData(
          await _repository.signUp(
            email: email,
            password: password,
            displayName: displayName,
          ),
        );
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }

  /// The app's second sign-in method. Behaves like the other two from the
  /// screen's point of view: submitting state while it runs, then either data
  /// or a readable error.
  Future<bool> signInWithGoogle() {
    return submit(() async {
      try {
        setData(await _repository.signInWithGoogle());
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }

  Future<bool> sendPasswordReset({required String email}) {
    return submit(() async {
      try {
        await _repository.sendPasswordReset(email: email);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }
}

final authControllerProvider =
    StateNotifierProvider.autoDispose<
      AuthController,
      ControllerState<AuthUser?>
    >((ref) => AuthController(ref.watch(authRepositoryProvider)));
