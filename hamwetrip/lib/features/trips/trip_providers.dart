import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_error.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/state/base_controller.dart';
import '../../core/state/stream_view_controller.dart';
import '../../domain/models/invite.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_member.dart';
import '../../domain/repositories/trip_repository.dart';

// ---------------------------------------------------------------------
// Read-only, trip-scoped streams
// ---------------------------------------------------------------------

final tripControllerProvider = StateNotifierProvider.autoDispose
    .family<StreamViewController<Trip?>, ControllerState<Trip?>, String>(
      (ref, tripId) =>
          StreamViewController<Trip?>(ref.watch(tripRepositoryProvider).watchTrip(tripId)),
    );

final tripMembersControllerProvider = StateNotifierProvider.autoDispose
    .family<
      StreamViewController<List<TripMember>>,
      ControllerState<List<TripMember>>,
      String
    >(
      (ref, tripId) => StreamViewController<List<TripMember>>(
        ref.watch(tripRepositoryProvider).watchMembers(tripId),
        isEmptyWhen: (members) => members.isEmpty,
      ),
    );

final myMembershipControllerProvider = StateNotifierProvider.autoDispose
    .family<StreamViewController<TripMember?>, ControllerState<TripMember?>, String>(
      (ref, tripId) => StreamViewController<TripMember?>(
        ref.watch(tripRepositoryProvider).watchMyMembership(tripId),
      ),
    );

/// See FirebaseTripRepository.watchInvites: this surfaces as a
/// PermissionDeniedError view state until firestore.rules grows the `list`
/// clause it needs — that is expected, not a bug in this provider.
final tripInvitesControllerProvider = StateNotifierProvider.autoDispose
    .family<StreamViewController<List<Invite>>, ControllerState<List<Invite>>, String>(
      (ref, tripId) => StreamViewController<List<Invite>>(
        ref.watch(tripRepositoryProvider).watchInvites(tripId),
        isEmptyWhen: (invites) => invites.isEmpty,
      ),
    );

// ---------------------------------------------------------------------
// Mutations
// ---------------------------------------------------------------------

class CreateTripController extends BaseController<Trip?> {
  CreateTripController(this._repository);

  final TripRepository _repository;

  Future<Trip?> create({
    required String name,
    required String destination,
    required String requestId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return submit(() async {
      try {
        final trip = await _repository.createTrip(
          name: name,
          destination: destination,
          requestId: requestId,
          startDate: startDate,
          endDate: endDate,
        );
        setData(trip);
        return trip;
      } on AppError catch (error) {
        setError(error);
        return null;
      }
    });
  }
}

final createTripControllerProvider =
    StateNotifierProvider.autoDispose<CreateTripController, ControllerState<Trip?>>(
      (ref) => CreateTripController(ref.watch(tripRepositoryProvider)),
    );

/// Organizer-only edits to an existing trip's details. `data` is just "did
/// the last edit succeed" — the dashboard reads the trip itself from
/// [tripControllerProvider], which updates on its own once this lands.
class TripDetailsController extends BaseController<bool> {
  TripDetailsController(this._repository);

  final TripRepository _repository;

  Future<bool> updateTrip({
    required String tripId,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    TripStatus? status,
  }) {
    return submit(() async {
      try {
        await _repository.updateTrip(
          tripId: tripId,
          name: name,
          destination: destination,
          startDate: startDate,
          endDate: endDate,
          status: status,
        );
        setData(true);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }
}

final tripDetailsControllerProvider = StateNotifierProvider.autoDispose<
  TripDetailsController,
  ControllerState<bool>
>((ref) => TripDetailsController(ref.watch(tripRepositoryProvider)));

/// Leave / remove / role-change: `data` is just "did the last action
/// succeed" — these screens act on the trip-scoped streams above for actual
/// content, this controller only tracks submission and errors.
class MembershipActionsController extends BaseController<bool> {
  MembershipActionsController(this._repository);

  final TripRepository _repository;

  Future<bool> leave(String tripId) => _run(() => _repository.leaveTrip(tripId));

  Future<bool> remove({required String tripId, required String uid}) =>
      _run(() => _repository.removeMember(tripId: tripId, uid: uid));

  Future<bool> changeRole({
    required String tripId,
    required String uid,
    required TripRole role,
  }) => _run(
    () => _repository.updateMemberRole(tripId: tripId, uid: uid, role: role),
  );

  Future<bool> _run(Future<void> Function() action) {
    return submit(() async {
      try {
        await action();
        setData(true);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }
}

final membershipActionsControllerProvider = StateNotifierProvider.autoDispose<
  MembershipActionsController,
  ControllerState<bool>
>((ref) => MembershipActionsController(ref.watch(tripRepositoryProvider)));

class InviteActionsController extends BaseController<Invite?> {
  InviteActionsController(this._repository);

  final TripRepository _repository;

  Future<Invite?> create({
    required String tripId,
    int maxUses = Invite.unlimitedUses,
    DateTime? expiresAt,
  }) {
    return submit(() async {
      try {
        final invite = await _repository.createInvite(
          tripId: tripId,
          maxUses: maxUses,
          expiresAt: expiresAt,
        );
        setData(invite);
        return invite;
      } on AppError catch (error) {
        setError(error);
        return null;
      }
    });
  }

  Future<bool> revoke({required String tripId, required String code}) {
    return submit(() async {
      try {
        await _repository.revokeInvite(tripId: tripId, code: code);
        return true;
      } on AppError catch (error) {
        setError(error);
        return false;
      }
    });
  }
}

final inviteActionsControllerProvider = StateNotifierProvider.autoDispose<
  InviteActionsController,
  ControllerState<Invite?>
>((ref) => InviteActionsController(ref.watch(tripRepositoryProvider)));
