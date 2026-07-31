import 'package:flutter/foundation.dart';

enum MomoType { send, receive }

enum MomoStatus { pending, completed }

MomoType _momoTypeFromString(String? value) {
  switch (value) {
    case 'send':
      return MomoType.send;
    case 'receive':
      return MomoType.receive;
    default:
      return MomoType.send;
  }
}

MomoStatus _momoStatusFromString(String? value) {
  switch (value) {
    case 'pending':
      return MomoStatus.pending;
    case 'completed':
      return MomoStatus.completed;
    default:
      return MomoStatus.pending;
  }
}

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

  Map<String, Object?> toMap() => {
    'name': name,
    'initials': initials,
    'maskedPhone': maskedPhone,
    'amount': amount,
    'type': type.name,
    'status': status.name,
  };

  factory MomoTransaction.fromMap(String id, Map<String, Object?> map) =>
      MomoTransaction(
        id: id,
        name: map['name'] as String? ?? '',
        initials: map['initials'] as String? ?? '',
        maskedPhone: map['maskedPhone'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        type: _momoTypeFromString(map['type'] as String?),
        status: _momoStatusFromString(map['status'] as String?),
      );
}
