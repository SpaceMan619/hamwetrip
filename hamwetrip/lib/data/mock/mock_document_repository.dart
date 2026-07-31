import 'dart:async';

import '../../data/models/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../features/shakira/data/demo/mock_documents.dart';

/// In-memory [DocumentRepository] backed by the existing mock data.
class MockDocumentRepository implements DocumentRepository {
  List<TripDocument> _docs = List.from(mockDocuments);
  final _controllers = <StreamController<List<TripDocument>>>[];

  @override
  Stream<List<TripDocument>> watchDocuments(String tripId) {
    final controller = StreamController<List<TripDocument>>();
    _controllers.add(controller);
    controller.add(List.from(_docs.reversed));
    return controller.stream;
  }

  void _notify() {
    for (final c in _controllers) {
      if (!c.isClosed) c.add(List.from(_docs.reversed));
    }
  }

  @override
  Future<TripDocument> uploadDocument({
    required String tripId,
    required String title,
    required String category,
    required DocType type,
    required String uploadedBy,
    required String uploadedByInitials,
    required String fileSize,
  }) async {
    final doc = TripDocument(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      type: type,
      uploadedBy: uploadedBy,
      uploadedByInitials: uploadedByInitials,
      fileSize: fileSize,
      date: DateTime.now(),
    );
    _docs = [..._docs, doc];
    _notify();
    return doc;
  }

  @override
  Future<void> deleteDocument({
    required String tripId,
    required String docId,
  }) async {
    _docs = _docs.where((d) => d.id != docId).toList();
    _notify();
  }

  void dispose() {
    for (final c in _controllers) {
      if (!c.isClosed) c.close();
    }
  }
}
