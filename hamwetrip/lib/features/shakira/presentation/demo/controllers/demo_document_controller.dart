import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../data/models/document.dart';
import '../../../../../domain/repositories/document_repository.dart';

class DemoDocumentController extends ChangeNotifier {
  final DocumentRepository _repository;
  final String tripId;

  List<TripDocument> _allDocuments = [];
  bool _isLoading = true;
  AppError? _error;
  String? _searchQuery;
  String _currentCategory = 'All';
  StreamSubscription<List<TripDocument>>? _subscription;

  DemoDocumentController({
    required DocumentRepository repository,
    this.tripId = 'demo-trip',
  }) : _repository = repository {
    _loadDocuments();
  }

  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get hasError => _error != null;

  List<TripDocument> get documents => _filteredDocuments;
  String get currentCategory => _currentCategory;
  List<String> get categories => [
    'All',
    'Bookings',
    'IDs',
    'Receipts',
    'Other',
  ];

  List<TripDocument> get _filteredDocuments {
    var result = _allDocuments.toList();
    if (_currentCategory != 'All') {
      result = result.where((d) => d.category == _currentCategory).toList();
    }
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      result = result.where((d) => d.title.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  void _loadDocuments() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _repository
        .watchDocuments(tripId)
        .listen(
          (docs) {
            _allDocuments = docs;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = error is AppError
                ? error
                : const UnknownError(message: 'Failed to load documents.');
            notifyListeners();
          },
        );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _loadDocuments();
  }

  void setCategory(String category) {
    _currentCategory = category;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  Future<void> deleteDocument(String docId) async {
    try {
      await _repository.deleteDocument(tripId: tripId, docId: docId);
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
  }

  Future<void> simulateUpload() async {
    try {
      await _repository.uploadDocument(
        tripId: tripId,
        title: 'New Document ${DateTime.now().millisecondsSinceEpoch}',
        category: 'Other',
        type: DocType.document,
        uploadedBy: 'Demo User',
        uploadedByInitials: 'DU',
        fileSize: '1.2 MB',
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
