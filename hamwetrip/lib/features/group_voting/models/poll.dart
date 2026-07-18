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
}
