import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/core/error/app_error.dart';
import 'package:hamwetrip/data/mock/mock_activity_repository.dart';
import 'package:hamwetrip/data/mock/mock_auth_repository.dart';
import 'package:hamwetrip/data/mock/mock_backend.dart';
import 'package:hamwetrip/data/mock/mock_trip_repository.dart';
import 'package:hamwetrip/data/mock/mock_user_repository.dart';
import 'package:hamwetrip/domain/models/trip.dart';
import 'package:hamwetrip/domain/models/trip_member.dart';

/// The mocks are a contract fixture, not throwaway scaffolding: the frontend
/// builds its loading/empty/error states against them, so their rules have to
/// match the rules the Firebase implementation will enforce in Phase 1 Stage 3.
void main() {
  late MockBackend backend;
  late MockAuthRepository auth;
  late MockTripRepository trips;
  late MockUserRepository users;
  late MockActivityRepository activity;

  const organizerId = 'u_aline';
  const memberId = 'u_eric';
  const tripId = 't_nyungwe';

  setUp(() {
    backend = MockBackend.seeded(latency: Duration.zero);
    auth = MockAuthRepository(backend);
    trips = MockTripRepository(backend);
    users = MockUserRepository(backend);
    activity = MockActivityRepository(backend);
  });

  tearDown(() => backend.dispose());

  group('seed data matches the guide fixtures', () {
    test('organizer, two members, one removed member, one pending invite', () {
      expect(backend.members[tripId]!.length, 3);
      expect(backend.members[tripId]![organizerId]!.role, TripRole.organizer);
      expect(backend.members[tripId]!.containsKey('u_jean'), isFalse);
      expect(
        backend.invites['HAMWE7']!.validate(now: DateTime.now().toUtc()),
        isNull,
      );
    });

    test('memberIds stays consistent with the members subcollection', () {
      final trip = backend.trips[tripId]!;
      expect(trip.memberIds.toSet(), backend.members[tripId]!.keys.toSet());
      expect(trip.memberCount, 3);
    });
  });

  group('auth', () {
    test(
      'signIn rejects a wrong password without revealing the account',
      () async {
        Object? thrown;
        try {
          await auth.signIn(email: 'aline@example.com', password: 'wrong');
        } catch (error) {
          thrown = error;
        }
        final missing = await auth
            .signIn(email: 'nobody@example.com', password: 'wrong')
            .then<Object?>((_) => null)
            .catchError((Object e) => e);

        expect(thrown, isA<AuthError>());
        // Identical messages: a different one for "no such account" would leak
        // which addresses are registered.
        expect((thrown! as AuthError).message, (missing! as AuthError).message);
      },
    );

    test('signUp rejects a duplicate email', () async {
      expect(
        () => auth.signUp(
          email: 'aline@example.com',
          password: 'hamwe1234',
          displayName: 'Impostor',
        ),
        throwsA(isA<AuthError>()),
      );
    });

    test('authState emits the session, then null after signOut', () async {
      final seen = <String?>[];
      final sub = auth.authState().listen((user) => seen.add(user?.uid));

      await Future<void>.delayed(Duration.zero);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, organizerId);
      expect(seen.last, isNull);
      await sub.cancel();
    });
  });

  group('createTrip', () {
    test('writes trip, organizer membership and activity together', () async {
      final trip = await trips.createTrip(
        name: 'Lake Kivu',
        destination: 'Rubavu',
        requestId: 'req-1',
      );

      expect(trip.ownerId, organizerId);
      expect(trip.memberIds, contains(organizerId));
      expect(backend.memberOf(trip.id, organizerId)!.role, TripRole.organizer);
      expect(backend.activity[trip.id], isNotEmpty);
    });

    test('is idempotent — a double tap creates one trip', () async {
      final first = await trips.createTrip(
        name: 'Lake Kivu',
        destination: 'Rubavu',
        requestId: 'req-1',
      );
      final second = await trips.createTrip(
        name: 'Lake Kivu',
        destination: 'Rubavu',
        requestId: 'req-1',
      );

      expect(first.id, second.id);
      expect(backend.trips.length, 2); // the seeded trip plus this one
    });

    test('rejects a blank name and an inverted date range', () async {
      expect(
        () =>
            trips.createTrip(name: '  ', destination: 'Rubavu', requestId: 'r'),
        throwsA(isA<InvalidInputError>()),
      );
      expect(
        () => trips.createTrip(
          name: 'Kivu',
          destination: 'Rubavu',
          requestId: 'r',
          startDate: DateTime.utc(2026, 10, 18),
          endDate: DateTime.utc(2026, 10, 12),
        ),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('joinTrip', () {
    setUp(() => backend.signedInUid = 'u_jean');

    test('redeems a valid code and increments usedCount', () async {
      final before = backend.invites['HAMWE7']!.usedCount;
      final trip = await trips.joinTrip(code: 'hamwe7');

      expect(trip.id, tripId);
      expect(backend.memberOf(tripId, 'u_jean')!.role, TripRole.member);
      expect(backend.invites['HAMWE7']!.usedCount, before + 1);
    });

    test('rejects an unknown, revoked, expired or exhausted code', () async {
      expect(
        () => trips.joinTrip(code: 'ZZZZZZ'),
        throwsA(isA<NotFoundError>()),
      );

      backend.invites['HAMWE7'] = backend.invites['HAMWE7']!.copyWith(
        revoked: true,
      );
      expect(
        () => trips.joinTrip(code: 'HAMWE7'),
        throwsA(isA<InvalidInputError>()),
      );

      backend.invites['HAMWE7'] = backend.invites['HAMWE7']!.copyWith(
        revoked: false,
        usedCount: 5,
        maxUses: 5,
      );
      expect(
        () => trips.joinTrip(code: 'HAMWE7'),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test('rejects a member who is already in the trip', () async {
      backend.signedInUid = memberId;
      expect(
        () => trips.joinTrip(code: 'HAMWE7'),
        throwsA(isA<AlreadyExistsError>()),
      );
    });
  });

  group('membership rules', () {
    test('a plain member cannot remove anyone', () async {
      backend.signedInUid = memberId;
      expect(
        () => trips.removeMember(tripId: tripId, uid: 'u_chantal'),
        throwsA(isA<PermissionDeniedError>()),
      );
    });

    test('the last organizer cannot leave', () async {
      expect(() => trips.leaveTrip(tripId), throwsA(isA<InvalidInputError>()));
    });

    test('the last organizer cannot demote themselves either', () async {
      expect(
        () => trips.updateMemberRole(
          tripId: tripId,
          uid: organizerId,
          role: TripRole.member,
        ),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test('an organizer can leave once another organizer exists', () async {
      await trips.updateMemberRole(
        tripId: tripId,
        uid: memberId,
        role: TripRole.organizer,
      );
      await trips.leaveTrip(tripId);

      expect(backend.memberOf(tripId, organizerId), isNull);
      expect(backend.trips[tripId]!.memberIds, isNot(contains(organizerId)));
    });

    test('removing a member clears memberIds in the same step', () async {
      await trips.removeMember(tripId: tripId, uid: memberId);
      expect(backend.trips[tripId]!.memberIds, isNot(contains(memberId)));
      expect(backend.memberOf(tripId, memberId), isNull);
    });

    test('a non-member cannot read the trip', () async {
      backend.signedInUid = 'u_jean';
      final trip = await trips.watchTrip(tripId).first;
      expect(trip, isNull);
    });
  });

  group('streams', () {
    test(
      'watchMyTrips is empty rather than an error when signed out',
      () async {
        backend.signedInUid = null;
        expect(await trips.watchMyTrips().first, isEmpty);
      },
    );

    test('watchMyTrips updates live when a trip is created', () async {
      final emissions = <int>[];
      final sub = trips.watchMyTrips().listen(
        (list) => emissions.add(list.length),
      );

      await Future<void>.delayed(Duration.zero);
      await trips.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'r1',
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions.first, 1);
      expect(emissions.last, 2);
      await sub.cancel();
    });

    test('activity is newest first and hidden from non-members', () async {
      final events = await activity.watchActivity(tripId).first;
      expect(events.first.summary, contains('removed'));

      backend.signedInUid = 'u_jean';
      expect(await activity.watchActivity(tripId).first, isEmpty);
    });

    test('watchActivity honours the paging limit', () async {
      expect((await activity.watchActivity(tripId, limit: 2).first).length, 2);
    });
  });

  group('profile', () {
    test('a rename fans out to the denormalized member documents', () async {
      await users.updateProfile(displayName: 'Aline U.');
      expect(backend.memberOf(tripId, organizerId)!.displayName, 'Aline U.');
    });

    test('a blank name is rejected', () async {
      expect(
        () => users.updateProfile(displayName: '   '),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('failure injection', () {
    test('a single injected failure applies once, then clears', () async {
      backend.failures['createTrip'] = const NetworkError();

      expect(
        () => trips.createTrip(
          name: 'Kivu',
          destination: 'Rubavu',
          requestId: 'r1',
        ),
        throwsA(isA<NetworkError>()),
      );
      // Lets a widget test drive: error state, then tap retry, then success.
      final retried = await trips.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'r1',
      );
      expect(retried.name, 'Kivu');
    });

    test(
      'a persistent failure keeps failing, for the retry-loop state',
      () async {
        backend.failures['watchMyTrips'] = const PermissionDeniedError();
        backend.persistentFailures.add('watchMyTrips');

        expect(
          trips.watchMyTrips().first,
          throwsA(isA<PermissionDeniedError>()),
        );
        expect(
          trips.watchMyTrips().first,
          throwsA(isA<PermissionDeniedError>()),
        );
      },
    );
  });

  group('trip status', () {
    test(
      'planning and active are editable, completed and archived are not',
      () {
        expect(TripStatus.planning, TripStatus.values.first);
        final trip = backend.trips[tripId]!;
        expect(trip.isEditable, isTrue);
        expect(trip.copyWith(status: TripStatus.archived).isEditable, isFalse);
        expect(trip.copyWith(status: TripStatus.completed).isEditable, isFalse);
      },
    );
  });
}
