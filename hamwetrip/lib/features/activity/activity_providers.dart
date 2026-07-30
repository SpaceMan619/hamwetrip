import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/state/base_controller.dart';
import '../../core/state/stream_view_controller.dart';
import '../../domain/models/activity_event.dart';

final tripActivityControllerProvider = StateNotifierProvider.autoDispose
    .family<
      StreamViewController<List<ActivityEvent>>,
      ControllerState<List<ActivityEvent>>,
      String
    >(
      (ref, tripId) => StreamViewController<List<ActivityEvent>>(
        ref.watch(activityRepositoryProvider).watchActivity(tripId),
        isEmptyWhen: (events) => events.isEmpty,
      ),
    );

/// The home feed: merges activity across every trip the signed-in user
/// belongs to — see FirebaseActivityRepository.watchMyActivity.
final myActivityControllerProvider = StateNotifierProvider.autoDispose<
  StreamViewController<List<ActivityEvent>>,
  ControllerState<List<ActivityEvent>>
>((ref) {
  ref.watch(authStateProvider);
  return StreamViewController<List<ActivityEvent>>(
    ref.watch(activityRepositoryProvider).watchMyActivity(),
    isEmptyWhen: (events) => events.isEmpty,
  );
});
