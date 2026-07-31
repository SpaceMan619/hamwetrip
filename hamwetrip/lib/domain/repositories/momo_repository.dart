import '../../data/models/momo_transaction.dart';

/// MoMo transactions for the MoMo summary screen.
abstract interface class MomoRepository {
  /// All MoMo transactions for a trip, live-updated.
  Stream<List<MomoTransaction>> watchTransactions(String tripId);

  /// Marks a "send" transaction as completed (payment sent).
  Future<void> payNow({required String tripId, required String transactionId});

  /// Marks a "receive" transaction as completed (payment requested).
  Future<void> requestPayment({
    required String tripId,
    required String transactionId,
  });
}
