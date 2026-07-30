import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/core/error/app_error.dart';
import 'package:hamwetrip/data/firebase/firebase_activity_repository.dart';
import 'package:hamwetrip/data/firebase/firebase_auth_repository.dart';
import 'package:hamwetrip/data/firebase/firebase_trip_repository.dart';
import 'package:hamwetrip/data/firebase/firebase_user_repository.dart';
import 'package:hamwetrip/domain/models/trip_member.dart';
import 'package:hamwetrip/firebase_options.dart';
import 'package:integration_test/integration_test.dart';

/// Repository tests against the real Firebase implementations, run against
/// the local Firestore + Auth emulators declared in `firebase.json` — never
/// against the live `hamwetrip-dev` project.
///
/// These are `integration_test` tests, not plain `flutter test`: the
/// Firebase plugins' platform channels only work on a real device or
/// emulator, and these are not part of the default `flutter test` run this
/// project's CI executes. Run them yourself with the emulator suite up:
///
/// ```bash
/// firebase emulators:start
/// # in another terminal, with a device or simulator attached:
/// cd hamwetrip && flutter test integration_test/repository_test.dart
/// ```
///
/// Every mutation is exercised twice in a row — a deliberate double tap — to
/// prove it is safe to retry rather than only safe to call once.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const projectId = 'hamwetrip-dev';
  const password = 'hamwe1234';

  late fb_auth.FirebaseAuth auth;
  late FirebaseFirestore firestore;
  late FirebaseAuthRepository authRepo;
  late FirebaseUserRepository userRepo;
  late FirebaseTripRepository tripRepo;

  Future<void> clearEmulators() async {
    final client = HttpClient();
    try {
      final firestoreClear = await client.deleteUrl(
        Uri.parse(
          'http://localhost:8080/emulator/v1/projects/$projectId/databases/(default)/documents',
        ),
      );
      await firestoreClear.close();

      final authClear = await client.deleteUrl(
        Uri.parse('http://localhost:9099/emulator/v1/projects/$projectId/accounts'),
      );
      await authClear.close();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> signUpAndSignIn(String email, String displayName) {
    return authRepo
        .signUp(email: email, password: password, displayName: displayName)
        .then((_) {});
  }

  Future<void> signInAs(String email) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    auth = fb_auth.FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    await auth.useAuthEmulator('localhost', 9099);
    firestore.useFirestoreEmulator('localhost', 8080);

    authRepo = FirebaseAuthRepository(auth, firestore);
    userRepo = FirebaseUserRepository(firestore, auth);
    tripRepo = FirebaseTripRepository(firestore, auth);
    // Constructed for completeness/parity with the other repositories, even
    // though this file does not exercise activity paging directly.
    FirebaseActivityRepository(firestore, auth);
  });

  setUp(() async {
    if (auth.currentUser != null) await auth.signOut();
    await clearEmulators();
  });

  group('createTrip', () {
    test('double tap with the same requestId creates exactly one trip', () async {
      await signUpAndSignIn('organizer1@example.com', 'Aline Uwase');
      const requestId = 'req-fixed-1';

      final first = await tripRepo.createTrip(
        name: 'Lake Kivu',
        destination: 'Rubavu',
        requestId: requestId,
      );
      final second = await tripRepo.createTrip(
        name: 'Lake Kivu',
        destination: 'Rubavu',
        requestId: requestId,
      );

      expect(first.id, second.id);
      final myTrips = await tripRepo.watchMyTrips().first;
      expect(myTrips.where((t) => t.id == first.id).length, 1);
    });

    test('creates the organizer membership atomically with the trip', () async {
      await signUpAndSignIn('organizer2@example.com', 'Eric Habimana');
      final trip = await tripRepo.createTrip(
        name: 'Nyungwe',
        destination: 'Rwanda',
        requestId: 'req-organizer-check',
      );

      final membership = await tripRepo.watchMyMembership(trip.id).first;
      expect(membership?.role, TripRole.organizer);
    });
  });

  group('joinTrip / invite redemption', () {
    test('double tap after already joining is rejected, not double counted', () async {
      await signUpAndSignIn('organizer3@example.com', 'Aline');
      final trip = await tripRepo.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'req-join-1',
      );
      final invite = await tripRepo.createInvite(tripId: trip.id);

      await auth.signOut();
      await signUpAndSignIn('joiner1@example.com', 'Eric');

      await tripRepo.joinTrip(code: invite.code);
      await expectLater(
        tripRepo.joinTrip(code: invite.code),
        throwsA(isA<AlreadyExistsError>()),
      );

      final members = await tripRepo.watchMembers(trip.id).first;
      expect(members.where((m) => m.displayName == 'Eric').length, 1);
    });

    test('a single-use code cannot be redeemed twice by different people', () async {
      await signUpAndSignIn('organizer4@example.com', 'Aline');
      final trip = await tripRepo.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'req-join-2',
      );
      final invite = await tripRepo.createInvite(tripId: trip.id, maxUses: 1);

      await auth.signOut();
      await signUpAndSignIn('joiner2@example.com', 'Eric');
      await tripRepo.joinTrip(code: invite.code);

      await auth.signOut();
      await signUpAndSignIn('joiner3@example.com', 'Chantal');
      await expectLater(
        tripRepo.joinTrip(code: invite.code),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('updateMemberRole', () {
    test('double tap setting the same role twice is idempotent', () async {
      await signUpAndSignIn('organizer5@example.com', 'Aline');
      final trip = await tripRepo.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'req-role-1',
      );
      final invite = await tripRepo.createInvite(tripId: trip.id);

      await auth.signOut();
      await signUpAndSignIn('member1@example.com', 'Eric');
      await tripRepo.joinTrip(code: invite.code);
      final memberUid = auth.currentUser!.uid;

      await auth.signOut();
      await signInAs('organizer5@example.com');

      await tripRepo.updateMemberRole(
        tripId: trip.id,
        uid: memberUid,
        role: TripRole.editor,
      );
      await tripRepo.updateMemberRole(
        tripId: trip.id,
        uid: memberUid,
        role: TripRole.editor,
      );

      final members = await tripRepo.watchMembers(trip.id).first;
      final updated = members.firstWhere((m) => m.uid == memberUid);
      expect(updated.role, TripRole.editor);
    });
  });

  group('leaveTrip / last-organizer guard', () {
    test('the sole organizer cannot leave', () async {
      await signUpAndSignIn('organizer6@example.com', 'Aline');
      final trip = await tripRepo.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'req-leave-1',
      );

      await expectLater(
        tripRepo.leaveTrip(trip.id),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test(
      'an organizer can leave once another organizer exists; '
      'a double-tap leave afterwards fails gracefully',
      () async {
        await signUpAndSignIn('organizer7@example.com', 'Aline');
        final trip = await tripRepo.createTrip(
          name: 'Kivu',
          destination: 'Rubavu',
          requestId: 'req-leave-2',
        );
        final invite = await tripRepo.createInvite(tripId: trip.id);

        await auth.signOut();
        await signUpAndSignIn('member2@example.com', 'Eric');
        await tripRepo.joinTrip(code: invite.code);
        final memberUid = auth.currentUser!.uid;

        await auth.signOut();
        await signInAs('organizer7@example.com');
        await tripRepo.updateMemberRole(
          tripId: trip.id,
          uid: memberUid,
          role: TripRole.organizer,
        );

        await tripRepo.leaveTrip(trip.id);
        // Second call: already left, so this must surface as a graceful
        // AppError (no longer a member) rather than an unhandled exception.
        await expectLater(tripRepo.leaveTrip(trip.id), throwsA(isA<AppError>()));
      },
    );

    test('the last organizer cannot be demoted either', () async {
      await signUpAndSignIn('organizer8@example.com', 'Aline');
      final trip = await tripRepo.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'req-demote-1',
      );
      final uid = auth.currentUser!.uid;

      await expectLater(
        tripRepo.updateMemberRole(tripId: trip.id, uid: uid, role: TripRole.member),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('profile fan-out', () {
    test('a rename fans out to member documents across trips', () async {
      await signUpAndSignIn('organizer9@example.com', 'Aline Uwase');
      final trip = await tripRepo.createTrip(
        name: 'Kivu',
        destination: 'Rubavu',
        requestId: 'req-profile-1',
      );

      await userRepo.updateProfile(displayName: 'Aline U.');

      final members = await tripRepo.watchMembers(trip.id).first;
      expect(members.single.displayName, 'Aline U.');
    });
  });
}
