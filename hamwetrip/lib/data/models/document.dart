import 'package:flutter/foundation.dart';

enum DocType { pdf, image, document }

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

  const TripDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.uploadedBy,
    required this.uploadedByInitials,
    required this.fileSize,
    required this.date,
  });

  Map<String, Object?> toMap() => {
    'title': title,
    'category': category,
    'type': _docTypeValues[type],
    'uploadedBy': uploadedBy,
    'uploadedByInitials': uploadedByInitials,
    'fileSize': fileSize,
    'date': date.toIso8601String(),
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
      );
}
