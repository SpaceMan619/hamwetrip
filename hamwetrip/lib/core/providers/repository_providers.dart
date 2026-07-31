import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firebase/firebase_activity_repository.dart';
import '../../data/firebase/firebase_auth_repository.dart';
import '../../data/firebase/firebase_document_repository.dart';
import '../../data/firebase/firebase_expense_repository.dart';
import '../../data/firebase/firebase_itinerary_repository.dart';
import '../../data/firebase/firebase_momo_repository.dart';
import '../../data/firebase/firebase_poll_repository.dart';
import '../../data/firebase/firebase_trip_repository.dart';
import '../../data/firebase/firebase_user_repository.dart';
import '../../data/mock/mock_activity_repository.dart';
import '../../data/mock/mock_auth_repository.dart';
import '../../data/mock/mock_backend.dart';
import '../../data/mock/mock_document_repository.dart';
import '../../data/mock/mock_expense_repository.dart';
import '../../data/mock/mock_itinerary_repository.dart';
import '../../data/mock/mock_momo_repository.dart';
import '../../data/mock/mock_poll_repository.dart';
import '../../data/mock/mock_trip_repository.dart';
import '../../data/mock/mock_user_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../domain/repositories/momo_repository.dart';
import '../../domain/repositories/poll_repository.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../config/app_config.dart';

/// Whether this provider graph wires the mock repositories.
///
/// A provider rather than reading [useMockRepositories] directly from every
/// repository provider, so a widget test can override just this one binding
/// to force mocks without touching the compile-time constant.
final useMockRepositoriesProvider = Provider<bool>(
  (ref) => useMockRepositories,
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// One shared in-memory backend for every mock repository, so a change made
/// through one — signing in, say — is visible to the others, mirroring how
/// the Firebase repositories all read and write the same project.
final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend.seeded();
  ref.onDispose(backend.dispose);
  return backend;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return MockAuthRepository(ref.watch(mockBackendProvider));
  }
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return MockUserRepository(ref.watch(mockBackendProvider));
  }
  return FirebaseUserRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return MockTripRepository(ref.watch(mockBackendProvider));
  }
  return FirebaseTripRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return MockActivityRepository(ref.watch(mockBackendProvider));
  }
  return FirebaseActivityRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

// ---------------------------------------------------------------------------
// Shakira-feature repositories (polls, expenses, itinerary, documents, momo).
//
// Each follows the same mock/Firebase switch as the Phase 1 repositories
// above, so `--dart-define=USE_MOCK_REPOSITORIES=true` still gives a fully
// offline-capable UI for the group-voting, expense-splitting, itinerary,
// document-vault and momo-summary screens.
// ---------------------------------------------------------------------------

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    final repo = MockPollRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirebasePollRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    final repo = MockExpenseRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirebaseExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    final repo = MockItineraryRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirebaseItineraryRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    final repo = MockDocumentRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirebaseDocumentRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final momoRepositoryProvider = Provider<MomoRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    final repo = MockMomoRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirebaseMomoRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

/// The app's single source of routing truth — see [AuthRepository.authState].
/// The shell watches this to swap between the auth stack and the main stack;
/// nothing else should decide whether a user is signed in.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authState();
});
