import 'package:flutter/foundation.dart';

@immutable
class ItineraryItem {
  final String id;
  final String time;
  final String title;
  final String location;
  final String description;
  final String emoji;
  final String type; // e.g., 'activity', 'transport', 'food'

  const ItineraryItem({
    required this.id,
    required this.time,
    required this.title,
    required this.location,
    required this.description,
    required this.emoji,
    required this.type,
  });
}

@immutable
class ItineraryDay {
  final String dayTitle;
  final String date;
  final List<ItineraryItem> items;

  const ItineraryDay({
    required this.dayTitle,
    required this.date,
    required this.items,
  });
}
