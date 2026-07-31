import 'dart:async';

import '../../data/models/momo_transaction.dart';
import '../../domain/repositories/momo_repository.dart';
import '../../features/shakira/data/demo/mock_momo.dart';

/// In-memory [MomoRepository] backed by the existing mock data.
class MockMomoRepository implements MomoRepository {
  final List<MomoTransaction> _transactions = List.from(mockMomoTransactions);
  final Set<String> _completedIds = {};
  final _controllers = <StreamController<List<MomoTransaction>>>[];

  @override
  Stream<List<MomoTransaction>> watchTransactions(String tripId) {
    final controller = StreamController<List<MomoTransaction>>();
    _controllers.add(controller);
    controller.add(_currentTransactions());
    return controller.stream;
  }

  List<MomoTransaction> _currentTransactions() {
    return _transactions
        .map(
          (t) => _completedIds.contains(t.id)
              ? MomoTransaction(
                  id: t.id,
                  name: t.name,
                  initials: t.initials,
                  maskedPhone: t.maskedPhone,
                  amount: t.amount,
                  type: t.type,
                  status: MomoStatus.completed,
                )
              : t,
        )
        .toList();
  }

  void _notify() {
    for (final c in _controllers) {
      if (!c.isClosed) c.add(_currentTransactions());
    }
  }

  @override
  Future<void> payNow({
    required String tripId,
    required String transactionId,
  }) async {
    _completedIds.add(transactionId);
    _notify();
  }

  @override
  Future<void> requestPayment({
    required String tripId,
    required String transactionId,
  }) async {
    _completedIds.add(transactionId);
    _notify();
  }

  void dispose() {
    for (final c in _controllers) {
      if (!c.isClosed) c.close();
    }
  }
}
