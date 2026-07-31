import '../../data/models/document.dart';

/// Trip documents for the document vault screen.
abstract interface class DocumentRepository {
  /// All documents for a trip, live-updated.
  Stream<List<TripDocument>> watchDocuments(String tripId);

  /// Uploads a new document metadata record.
  Future<TripDocument> uploadDocument({
    required String tripId,
    required String title,
    required String category,
    required DocType type,
    required String uploadedBy,
    required String uploadedByInitials,
    required String fileSize,
  });

  /// Deletes a document.
  Future<void> deleteDocument({required String tripId, required String docId});
}
