import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/state/base_controller.dart';
import '../../core/state/stream_view_controller.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/trip.dart';

/// The signed-in user's trips, newest first — backs the home feed.
final myTripsControllerProvider =
    StateNotifierProvider.autoDispose<
      StreamViewController<List<Trip>>,
      ControllerState<List<Trip>>
    >((ref) {
      // Watched so this rebuilds on sign-in/out — the underlying repository
      // call reads `FirebaseAuth.currentUser` fresh rather than keeping a
      // stale uid alive across a sign-out.
      ref.watch(authStateProvider);
      final repository = ref.watch(tripRepositoryProvider);
      return StreamViewController<List<Trip>>(
        repository.watchMyTrips(),
        isEmptyWhen: (trips) => trips.isEmpty,
      );
    });

/// The signed-in user's own profile document.
final currentUserProfileProvider =
    StateNotifierProvider.autoDispose<
      StreamViewController<AppUser?>,
      ControllerState<AppUser?>
    >((ref) {
      final session = ref.watch(authStateProvider).valueOrNull;
      final repository = ref.watch(userRepositoryProvider);
      if (session == null) {
        return StreamViewController<AppUser?>(Stream.value(null));
      }
      return StreamViewController<AppUser?>(repository.watchUser(session.uid));
    });
