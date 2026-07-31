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

  Map<String, Object?> toMap() => {
    'time': time,
    'title': title,
    'location': location,
    'description': description,
    'emoji': emoji,
    'type': type,
  };

  factory ItineraryItem.fromMap(String id, Map<String, Object?> map) =>
      ItineraryItem(
        id: id,
        time: map['time'] as String? ?? '',
        title: map['title'] as String? ?? '',
        location: map['location'] as String? ?? '',
        description: map['description'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '',
        type: map['type'] as String? ?? 'activity',
      );
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

  Map<String, Object?> toMap() => {
    'dayTitle': dayTitle,
    'date': date,
    'items': items.map((i) => i.toMap()).toList(),
  };

  factory ItineraryDay.fromMap(Map<String, Object?> map) => ItineraryDay(
    dayTitle: map['dayTitle'] as String? ?? '',
    date: map['date'] as String? ?? '',
    items: (map['items'] as List<dynamic>? ?? [])
        .map(
          (i) => ItineraryItem.fromMap('', Map<String, Object?>.from(i as Map)),
        )
        .toList(),
  );
}
