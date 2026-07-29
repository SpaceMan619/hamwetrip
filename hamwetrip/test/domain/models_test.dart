import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/domain/models/activity_event.dart';
import 'package:hamwetrip/domain/models/app_user.dart';
import 'package:hamwetrip/domain/models/invite.dart';
import 'package:hamwetrip/domain/models/model_parsing.dart';
import 'package:hamwetrip/domain/models/trip.dart';
import 'package:hamwetrip/domain/models/trip_member.dart';

/// Stands in for Firestore's `Timestamp`, which the domain layer deliberately
/// does not import. If [parseDateTime]'s duck-typing ever breaks, every model's
/// timestamps silently become null — so it is worth an explicit test.
class FakeTimestamp {
  FakeTimestamp(this._value);
  final DateTime _value;
  DateTime toDate() => _value;
}

void main() {
  final now = DateTime.utc(2026, 7, 29, 10, 30);

  group('parseDateTime', () {
    test('reads every shape the three data sources produce', () {
      expect(parseDateTime(now), now);
      expect(parseDateTime(FakeTimestamp(now)), now);
      expect(parseDateTime(now.toIso8601String()), now);
      expect(parseDateTime(now.millisecondsSinceEpoch), now);
    });

    test('returns null for an unacknowledged server timestamp', () {
      // This is the offline-create case: `FieldValue.serverTimestamp()` reads
      // back null locally until the server confirms the write.
      expect(parseDateTime(null), isNull);
    });

    test('normalizes to UTC', () {
      final local = DateTime(2026, 7, 29, 10, 30);
      expect(parseDateTime(local)!.isUtc, isTrue);
    });

    test('returns null rather than throwing on junk', () {
      expect(parseDateTime('not a date'), isNull);
      expect(parseDateTime(const <String>[]), isNull);
    });
  });

  group('parseWireEnum', () {
    test('matches on the stored wire value, not the Dart constant name', () {
      expect(
        parseWireEnum(
          'vote_cast',
          ActivityType.values,
          (t) => t.wire,
          ActivityType.unknown,
        ),
        ActivityType.voteCast,
      );
    });

    test('falls back instead of throwing on an unrecognized value', () {
      // A client running an older build must not crash when the backend starts
      // writing an event type it has never heard of.
      expect(
        parseWireEnum(
          'teleported',
          ActivityType.values,
          (t) => t.wire,
          ActivityType.unknown,
        ),
        ActivityType.unknown,
      );
      expect(
        parseWireEnum(
          null,
          TripStatus.values,
          (s) => s.wire,
          TripStatus.unknown,
        ),
        TripStatus.unknown,
      );
    });
  });

  group('round trips', () {
    test('AppUser', () {
      final user = AppUser(
        uid: 'u1',
        displayName: 'Aline Uwase',
        email: 'aline@example.com',
        phone: '0788123456',
        photoUrl: 'https://example.com/a.png',
        createdAt: now,
        notificationsEnabled: false,
      );
      expect(AppUser.fromMap(user.uid, user.toMap()), user);
    });

    test('Trip', () {
      final trip = Trip(
        id: 't1',
        name: 'Nyungwe National Park',
        destination: 'Rwanda',
        ownerId: 'u1',
        currency: 'RWF',
        status: TripStatus.planning,
        memberIds: const ['u1', 'u2'],
        startDate: now,
        endDate: now.add(const Duration(days: 6)),
        createdAt: now,
        updatedAt: now,
      );
      expect(Trip.fromMap(trip.id, trip.toMap()), trip);
    });

    test('TripMember', () {
      final member = TripMember(
        uid: 'u1',
        tripId: 't1',
        role: TripRole.organizer,
        displayName: 'Aline Uwase',
        photoUrl: null,
        joinedAt: now,
        balanceMinor: -2500,
      );
      expect(
        TripMember.fromMap(member.tripId, member.uid, member.toMap()),
        member,
      );
    });

    test('Invite', () {
      final invite = Invite(
        code: 'HAMWE7',
        tripId: 't1',
        createdBy: 'u1',
        maxUses: 5,
        usedCount: 2,
        revoked: false,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 20)),
      );
      expect(Invite.fromMap(invite.code, invite.toMap()), invite);
    });

    test('ActivityEvent', () {
      final event = ActivityEvent(
        id: 'a1',
        tripId: 't1',
        type: ActivityType.paymentConfirmed,
        actorId: 'u1',
        actorName: 'Aline Uwase',
        summary: 'Aline confirmed a settlement',
        entityId: 'p1',
        createdAt: now,
      );
      expect(
        ActivityEvent.fromMap(event.tripId, event.id, event.toMap()),
        event,
      );
    });
  });

  group('missing and malformed fields', () {
    test('an empty document parses to safe defaults', () {
      final trip = Trip.fromMap('t1', const <String, Object?>{});
      expect(trip.name, '');
      expect(trip.currency, 'RWF');
      expect(trip.status, TripStatus.unknown);
      expect(trip.memberIds, isEmpty);
      expect(trip.isPending, isTrue);
    });

    test('a pending local write leaves timestamps null', () {
      final trip = Trip.fromMap('t1', <String, Object?>{
        'name': 'Kivu',
        'createdAt': null,
      });
      expect(trip.isPending, isTrue);
      expect(trip.createdAt, isNull);
    });

    test('a malformed memberIds entry is dropped, not fatal', () {
      final trip = Trip.fromMap('t1', <String, Object?>{
        'memberIds': <Object?>['u1', 42, null, 'u2'],
      });
      expect(trip.memberIds, <String>['u1', 'u2']);
    });
  });

  group('derived behaviour', () {
    test('memberCount cannot drift from memberIds', () {
      final trip = Trip.fromMap('t1', <String, Object?>{
        'memberIds': <Object?>['u1', 'u2', 'u3'],
      });
      expect(trip.memberCount, 3);
    });

    test('initials handle one word, two words, and empty names', () {
      expect(
        AppUser.fromMap('u', {'displayName': 'Aline Uwase'}).initials,
        'AU',
      );
      expect(AppUser.fromMap('u', {'displayName': 'Aline'}).initials, 'A');
      expect(AppUser.fromMap('u', {'displayName': '   '}).initials, '?');
      expect(
        AppUser.fromMap('u', {'displayName': 'Aline Grace Uwase'}).initials,
        'AU',
      );
    });

    test('role permissions match the guide', () {
      expect(TripRole.organizer.canManageMembership, isTrue);
      expect(TripRole.member.canManageMembership, isFalse);
      // The guide grants itinerary writes to "organizer/editor".
      expect(TripRole.editor.canEditItinerary, isTrue);
      expect(TripRole.member.canEditItinerary, isFalse);
      // An unrecognized role must be the least privileged, never the most.
      expect(TripRole.unknown.canManageMembership, isFalse);
      expect(TripRole.unknown.canEditItinerary, isFalse);
    });

    test('activity events know where to deep-link', () {
      final event = ActivityEvent.fromMap('t1', 'a1', {
        'type': 'expense_added',
        'entityId': 'e1',
      });
      expect(event.type.entityKind, ActivityEntityKind.expense);
      expect(event.canDeepLink, isTrue);

      final unknown = ActivityEvent.fromMap('t1', 'a2', {
        'type': 'future_kind',
      });
      expect(unknown.canDeepLink, isFalse);
    });
  });

  group('Invite', () {
    test('rejects for the specific reason, so the UI can explain', () {
      final base = Invite(
        code: 'HAMWE7',
        tripId: 't1',
        createdBy: 'u1',
        maxUses: 2,
        usedCount: 0,
        revoked: false,
        expiresAt: now.add(const Duration(days: 1)),
      );

      expect(base.validate(now: now), isNull);
      expect(
        base.copyWith(revoked: true).validate(now: now),
        InviteRejection.revoked,
      );
      expect(
        base.validate(now: now.add(const Duration(days: 2))),
        InviteRejection.expired,
      );
      expect(
        base.copyWith(usedCount: 2).validate(now: now),
        InviteRejection.exhausted,
      );
    });

    test('an invite expiring exactly now is already expired', () {
      final invite = Invite(
        code: 'HAMWE7',
        tripId: 't1',
        createdBy: 'u1',
        maxUses: Invite.unlimitedUses,
        usedCount: 0,
        revoked: false,
        expiresAt: now,
      );
      expect(invite.validate(now: now), InviteRejection.expired);
    });

    test('unlimited uses never exhaust', () {
      final invite = Invite(
        code: 'HAMWE7',
        tripId: 't1',
        createdBy: 'u1',
        maxUses: Invite.unlimitedUses,
        usedCount: 9999,
        revoked: false,
      );
      expect(invite.validate(now: now), isNull);
    });

    test('generated codes avoid visually ambiguous characters', () {
      for (var i = 0; i < 200; i++) {
        final code = Invite.generateCode();
        expect(code.length, Invite.codeLength);
        expect(
          RegExp(r'^[' + Invite.codeAlphabet + r']+$').hasMatch(code),
          isTrue,
        );
        expect(code.contains(RegExp(r'[01OIL]')), isFalse);
      }
    });

    test('normalizes codes the way people retype them', () {
      expect(Invite.normalizeCode('  hamwe7 '), 'HAMWE7');
      expect(Invite.normalizeCode('HAM-WE7'), 'HAMWE7');
    });
  });
}
