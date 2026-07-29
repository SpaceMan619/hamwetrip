import 'package:flutter/foundation.dart';
import '../../../../../data/models/document.dart';
import '../../../../../features/shakira/data/demo/mock_documents.dart';

class DemoDocumentController extends ChangeNotifier {
  final List<TripDocument> _allDocuments = List.from(mockDocuments);
  String? _searchQuery;
  String _filterCategory = 'All';

  List<TripDocument> get documents => _filteredDocuments;
  int get totalDocuments => _allDocuments.length;
  String get currentCategory => _filterCategory;

  List<String> get categories => [
    'All',
    'Identity',
    'Booking',
    'Insurance',
    'Other',
  ];

  List<TripDocument> get _filteredDocuments {
    var result = _allDocuments.toList();

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      result = result
          .where(
            (d) =>
                d.title.toLowerCase().contains(q) ||
                d.uploadedBy.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_filterCategory != 'All') {
      result = result.where((d) => d.category == _filterCategory).toList();
    }

    // Show newest uploads first
    return result.reversed.toList();
  }

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  void setCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void deleteDocument(String docId) {
    _allDocuments.removeWhere((d) => d.id == docId);
    notifyListeners();
  }

  void simulateUpload() {
    _allDocuments.add(
      TripDocument(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New_Upload_Simulated.pdf',
        category: 'Other',
        type: DocType.pdf,
        uploadedBy: 'Rajveer Malik',
        uploadedByInitials: 'RM',
        fileSize: '1.0 MB',
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
