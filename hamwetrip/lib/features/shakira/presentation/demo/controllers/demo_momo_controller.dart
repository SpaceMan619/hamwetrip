import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../data/models/momo_transaction.dart';
import '../../../../../domain/repositories/momo_repository.dart';

class DemoMomoController extends ChangeNotifier {
  final MomoRepository _repository;
  final String tripId;

  List<MomoTransaction> _transactions = [];
  bool _isLoading = true;
  AppError? _error;
  StreamSubscription<List<MomoTransaction>>? _subscription;

  DemoMomoController({
    required MomoRepository repository,
    this.tripId = 'demo-trip',
  }) : _repository = repository {
    _loadTransactions();
  }

  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get hasError => _error != null;

  List<MomoTransaction> get toSend =>
      _transactions.where((t) => t.type == MomoType.send).toList();
  List<MomoTransaction> get toReceive =>
      _transactions.where((t) => t.type == MomoType.receive).toList();

  double get totalSendAmount => toSend.fold(0.0, (sum, t) => sum + t.amount);
  double get totalReceiveAmount =>
      toReceive.fold(0.0, (sum, t) => sum + t.amount);

  void _loadTransactions() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _repository
        .watchTransactions(tripId)
        .listen(
          (transactions) {
            _transactions = transactions;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = error is AppError
                ? error
                : const UnknownError(message: 'Failed to load transactions.');
            notifyListeners();
          },
        );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _loadTransactions();
  }

  Future<void> payNow(String transactionId) async {
    try {
      await _repository.payNow(tripId: tripId, transactionId: transactionId);
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
  }

  Future<void> requestPayment(String transactionId) async {
    try {
      await _repository.requestPayment(
        tripId: tripId,
        transactionId: transactionId,
      );
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
