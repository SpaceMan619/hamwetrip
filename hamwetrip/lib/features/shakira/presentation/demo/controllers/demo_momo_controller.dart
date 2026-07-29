import 'package:flutter/foundation.dart';
import '../../../../../data/models/momo_transaction.dart';
import '../../../../../features/shakira/data/demo/mock_momo.dart';

class DemoMomoController extends ChangeNotifier {
  final List<MomoTransaction> _allTransactions = List.from(
    mockMomoTransactions,
  );

  // Tracks which transactions have been acted upon in the demo
  final Set<String> _completedIds = {};

  List<MomoTransaction> get toSend => _allTransactions
      .where((t) => t.type == MomoType.send)
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

  List<MomoTransaction> get toReceive => _allTransactions
      .where((t) => t.type == MomoType.receive)
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

  double get totalSendAmount => toSend.fold(0.0, (sum, t) => sum + t.amount);
  double get totalReceiveAmount =>
      toReceive.fold(0.0, (sum, t) => sum + t.amount);

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  void payNow(String transactionId) {
    _completedIds.add(transactionId);
    notifyListeners();
  }

  void requestPayment(String transactionId) {
    _completedIds.add(transactionId);
    notifyListeners();
  }
}
