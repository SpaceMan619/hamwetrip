import '../../data/models/document.dart';

/// Trip documents for the document vault screen.
abstract interface class DocumentRepository {
  /// All documents for a trip, live-updated.
  Stream<List<TripDocument>> watchDocuments(String tripId);

  /// Uploads a new document metadata record.
  ///
  /// [localPath] is where the file itself was copied on the uploading device —
  /// see `DocumentFileStore`. It is recorded so that device can reopen the file
  /// offline; another member reading the same record simply finds no file
  /// there and is offered the metadata alone.
  Future<TripDocument> uploadDocument({
    required String tripId,
    required String title,
    required String category,
    required DocType type,
    required String uploadedBy,
    required String uploadedByInitials,
    required String fileSize,
    String? localPath,
  });

  /// Deletes a document.
  Future<void> deleteDocument({required String tripId, required String docId});
}
