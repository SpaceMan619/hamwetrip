import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../data/local/document_file_store.dart';
import '../../../../../data/models/document.dart';
import '../../../../../domain/repositories/document_repository.dart';

class DemoDocumentController extends ChangeNotifier {
  final DocumentRepository _repository;
  final DocumentFileStore _fileStore;
  final String tripId;

  List<TripDocument> _allDocuments = [];
  Set<String> _availablePaths = const {};
  bool _isLoading = true;
  bool _isUploading = false;
  AppError? _error;
  String? _searchQuery;
  String _currentCategory = 'All';
  StreamSubscription<List<TripDocument>>? _subscription;

  DemoDocumentController({
    required DocumentRepository repository,
    this.tripId = 'demo-trip',
    DocumentFileStore fileStore = const DocumentFileStore(),
  }) : _repository = repository,
       _fileStore = fileStore {
    _loadDocuments();
  }

  bool get isLoading => _isLoading;

  /// True while a picked file is being copied and its record written, so the
  /// screen can block a second tap on the upload button.
  bool get isUploading => _isUploading;
  AppError? get error => _error;
  bool get hasError => _error != null;

  List<TripDocument> get documents => _filteredDocuments;

  /// How many of the vault's documents this device actually holds the file
  /// for — what "cached locally, available offline" means.
  int get cachedCount => _allDocuments.where(hasFile).length;

  /// Whether [document]'s file is on this device and can be opened right now.
  ///
  /// Answered from a set refreshed whenever the list changes rather than by
  /// touching the disk, so the grid can ask once per card per build.
  bool hasFile(TripDocument document) =>
      document.localPath != null &&
      _availablePaths.contains(document.localPath);

  String get currentCategory => _currentCategory;
  List<String> get categories => const ['All', ...documentCategories];

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
            _availablePaths = {
              for (final doc in docs)
                if (DocumentFileStore.hasFile(doc.localPath)) doc.localPath!,
            };
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

  /// Removes the record and, with it, the copy of the file this device holds.
  ///
  /// Returns whether it worked, so the caller can report the failure instead of
  /// claiming a delete that never happened.
  Future<bool> deleteDocument(TripDocument document) async {
    try {
      await _repository.deleteDocument(tripId: tripId, docId: document.id);
      await _fileStore.delete(document.localPath);
      return true;
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
      return false;
    }
  }

  /// Copies a picked file into the vault and records it.
  ///
  /// The file is stored first: a record pointing at a file that failed to copy
  /// would show up in the grid as a document that cannot be opened, which is
  /// worse than no record at all.
  Future<bool> uploadDocument({
    required String sourcePath,
    required String fileName,
    required String title,
    required String category,
    required String uploadedBy,
    required String uploadedByInitials,
  }) async {
    if (_isUploading) return false;
    _isUploading = true;
    _error = null;
    notifyListeners();

    StoredDocumentFile? stored;
    try {
      stored = await _fileStore.save(
        tripId: tripId,
        sourcePath: sourcePath,
        fileName: fileName,
      );
      await _repository.uploadDocument(
        tripId: tripId,
        title: title,
        category: category,
        type: docTypeForFileName(fileName),
        uploadedBy: uploadedBy,
        uploadedByInitials: uploadedByInitials,
        fileSize: stored.sizeLabel,
        localPath: stored.path,
      );
      return true;
    } on AppError catch (e) {
      await _fileStore.delete(stored?.path);
      _error = e;
      return false;
    } catch (e) {
      await _fileStore.delete(stored?.path);
      _error = UnknownError(cause: e);
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
