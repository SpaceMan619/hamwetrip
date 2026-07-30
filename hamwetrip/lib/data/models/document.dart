import 'package:flutter/foundation.dart';

enum DocType { pdf, image, document }

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
}
