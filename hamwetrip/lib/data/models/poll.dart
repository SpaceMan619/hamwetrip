import 'package:flutter/foundation.dart';

@immutable
class PollOption {
  final String id;
  final String label;
  final String? emoji;
  final int voteCount;

  const PollOption({
    required this.id,
    required this.label,
    this.emoji,
    this.voteCount = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'label': label,
    if (emoji != null) 'emoji': emoji,
    'voteCount': voteCount,
  };

  factory PollOption.fromMap(Map<String, Object?> map) => PollOption(
    id: map['id'] as String,
    label: map['label'] as String,
    emoji: map['emoji'] as String?,
    voteCount: (map['voteCount'] as num?)?.toInt() ?? 0,
  );
}

@immutable
class Poll {
  final String id;
  final String question;
  final String category;
  final String categoryEmoji;
  final List<PollOption> options;
  final int totalMembers;
  final DateTime? deadline;
  final bool isActive;
  final List<String> voterInitials;
  final String createdBy;

  int get totalVotes =>
      options.fold(0, (sum, option) => sum + option.voteCount);

  const Poll({
    required this.id,
    required this.question,
    required this.category,
    required this.categoryEmoji,
    required this.options,
    required this.totalMembers,
    this.deadline,
    required this.isActive,
    required this.voterInitials,
    required this.createdBy,
  });

  Map<String, Object?> toMap() => {
    'question': question,
    'category': category,
    'categoryEmoji': categoryEmoji,
    'options': options.map((o) => o.toMap()).toList(),
    'totalMembers': totalMembers,
    'deadline': deadline?.toIso8601String(),
    'isActive': isActive,
    'voterInitials': voterInitials,
    'createdBy': createdBy,
  };

  factory Poll.fromMap(String id, Map<String, Object?> map) => Poll(
    id: id,
    question: map['question'] as String,
    category: map['category'] as String? ?? '',
    categoryEmoji: map['categoryEmoji'] as String? ?? '',
    options: (map['options'] as List<dynamic>? ?? [])
        .map((o) => PollOption.fromMap(Map<String, Object?>.from(o as Map)))
        .toList(),
    totalMembers: (map['totalMembers'] as num?)?.toInt() ?? 0,
    deadline: map['deadline'] != null
        ? DateTime.parse(map['deadline'] as String)
        : null,
    isActive: map['isActive'] as bool? ?? true,
    voterInitials: (map['voterInitials'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    createdBy: map['createdBy'] as String? ?? '',
  );
}
