import 'package:flutter/foundation.dart';

enum MomoType { send, receive }

enum MomoStatus { pending, completed }

@immutable
class MomoTransaction {
  final String id;
  final String name;
  final String initials;
  final String maskedPhone; // e.g., "078X-XXX-456"
  final double amount;
  final MomoType type;
  final MomoStatus status;

  const MomoTransaction({
    required this.id,
    required this.name,
    required this.initials,
    required this.maskedPhone,
    required this.amount,
    required this.type,
    required this.status,
  });
}
