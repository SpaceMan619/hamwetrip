import 'package:flutter/foundation.dart';

enum DocType { pdf, image, document }

/// The vault's filing cabinet.
///
/// One list, used by the upload form, the filter chips and the seeded demo
/// documents alike — when these drifted apart, documents were filed under
/// names no chip could ever select, and the grid looked empty.
const documentCategories = <String>['Bookings', 'IDs', 'Receipts', 'Other'];

const _docTypeValues = {
  DocType.pdf: 'pdf',
  DocType.image: 'image',
  DocType.document: 'document',
};

DocType _docTypeFromString(String? value) {
  switch (value) {
    case 'pdf':
      return DocType.pdf;
    case 'image':
      return DocType.image;
    case 'document':
      return DocType.document;
    default:
      return DocType.document;
  }
}

@immutable
class TripDocument {
  final String id;
  final String title;
  final String category;
  final DocType type;
  final String uploadedBy;
  final String uploadedByInitials;
  final String fileSize;
  final DateTime date;

  /// Where the actual file sits on this device, or null for a record whose
  /// bytes this phone has never held — one somebody else uploaded, or one of
  /// the seeded demo entries.
  ///
  /// Stored alongside the metadata rather than derived from the id because the
  /// path includes the original file name, which is what the viewer hands to
  /// the platform to pick an app to open it with.
  final String? localPath;

  const TripDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.uploadedBy,
    required this.uploadedByInitials,
    required this.fileSize,
    required this.date,
    this.localPath,
  });

  Map<String, Object?> toMap() => {
    'title': title,
    'category': category,
    'type': _docTypeValues[type],
    'uploadedBy': uploadedBy,
    'uploadedByInitials': uploadedByInitials,
    'fileSize': fileSize,
    'date': date.toIso8601String(),
    'localPath': localPath,
  };

  factory TripDocument.fromMap(String id, Map<String, Object?> map) =>
      TripDocument(
        id: id,
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? '',
        type: _docTypeFromString(map['type'] as String?),
        uploadedBy: map['uploadedBy'] as String? ?? '',
        uploadedByInitials: map['uploadedByInitials'] as String? ?? '',
        fileSize: map['fileSize'] as String? ?? '',
        date: map['date'] != null
            ? DateTime.parse(map['date'] as String)
            : DateTime.now(),
        localPath: map['localPath'] as String?,
      );
}
