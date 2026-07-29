import 'dart:math';

import 'package:flutter/foundation.dart';

import 'model_parsing.dart';

/// Why an invite code cannot be redeemed. Returned by [Invite.validate] so the
/// join screen can show a specific message instead of a generic failure.
enum InviteRejection { expired, revoked, exhausted }

/// A shareable trip invitation. Mirrors **top-level** `invites/{code}`.
///
/// **The code is the document id.** That makes uniqueness a property of the
/// database rather than something a client has to guarantee with a
/// read-then-write, which would race whenever two organizers generate a code at
/// the same moment.
///
/// ## Why this is not a subcollection
///
/// The delivery guide nests every trip-owned document under the trip, and for
/// polls, expenses and documents that is right. Invites are the one exception:
/// `joinTrip(code)` is handed a bare code by someone who is **not yet a member
/// and does not know the trip id**. A path like `trips/{tripId}/invites/{code}`
/// cannot be resolved without the very trip id the code is supposed to reveal.
///
/// So this collection is global, and [tripId] is stored inside the document
/// rather than implied by the path. The security rule must therefore allow a
/// signed-in user to `get` a single invite by exact code while forbidding
/// `list` — otherwise the collection becomes an enumerable directory of every
/// trip in the system.
@immutable
class Invite {
  const Invite({
    required this.code,
    required this.tripId,
    required this.createdBy,
    required this.maxUses,
    required this.usedCount,
    required this.revoked,
    this.createdAt,
    this.expiresAt,
  });

  /// The shareable code, and the document id. Always stored uppercase.
  final String code;

  final String tripId;

  /// uid of the organizer who generated it.
  final String createdBy;

  /// How many times this code may be redeemed. Use [unlimitedUses] for no cap.
  final int maxUses;

  /// Incremented inside the same transaction that creates the membership, so
  /// two simultaneous joins on a single-use code cannot both succeed.
  final int usedCount;

  /// Organizers can kill a leaked code without waiting for it to expire.
  final bool revoked;

  final DateTime? createdAt;

  /// Null means the code never expires.
  final DateTime? expiresAt;

  /// Sentinel for [maxUses] meaning "no limit".
  static const int unlimitedUses = -1;

  /// Characters that cannot be confused when a code is read aloud or copied
  /// off a screen: no `0`/`O`, no `1`/`I`/`L`.
  static const String codeAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  static const int codeLength = 6;

  bool get hasUsesRemaining => maxUses == unlimitedUses || usedCount < maxUses;

  /// Checks redeemability at [now], which is injected rather than read from the
  /// device clock so this is deterministic under test. The authoritative check
  /// still happens server-side inside the join transaction — this exists to
  /// fail fast and to explain *why* to the user.
  ///
  /// Returns null when the invite is usable.
  InviteRejection? validate({required DateTime now}) {
    if (revoked) return InviteRejection.revoked;
    if (expiresAt != null && !now.toUtc().isBefore(expiresAt!.toUtc())) {
      return InviteRejection.expired;
    }
    if (!hasUsesRemaining) return InviteRejection.exhausted;
    return null;
  }

  /// Generates a random code from [codeAlphabet].
  ///
  /// Collisions are possible and are expected to be handled by the caller
  /// retrying the create — because the code is the document id, a collision
  /// surfaces as a failed create rather than as silent data corruption.
  static String generateCode({Random? random}) {
    final rng = random ?? Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < codeLength; i++) {
      buffer.write(codeAlphabet[rng.nextInt(codeAlphabet.length)]);
    }
    return buffer.toString();
  }

  /// Normalizes user input: trims, uppercases, and strips separators people add
  /// when retyping a code they were sent.
  static String normalizeCode(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
  }

  factory Invite.fromMap(String code, Map<String, Object?> data) {
    return Invite(
      code: code.toUpperCase(),
      tripId: parseString(data['tripId']),
      createdBy: parseString(data['createdBy']),
      maxUses: parseInt(data['maxUses'], fallback: unlimitedUses),
      usedCount: parseInt(data['usedCount']),
      revoked: parseBool(data['revoked']),
      createdAt: parseDateTime(data['createdAt']),
      expiresAt: parseDateTime(data['expiresAt']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      // Stored, not implied by the path — see the class doc.
      'tripId': tripId,
      'createdBy': createdBy,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'revoked': revoked,
      'createdAt': writeDateTime(createdAt),
      'expiresAt': writeDateTime(expiresAt),
    };
  }

  Invite copyWith({
    String? createdBy,
    int? maxUses,
    int? usedCount,
    bool? revoked,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return Invite(
      code: code,
      tripId: tripId,
      createdBy: createdBy ?? this.createdBy,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      revoked: revoked ?? this.revoked,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Invite &&
        other.code == code &&
        other.tripId == tripId &&
        other.createdBy == createdBy &&
        other.maxUses == maxUses &&
        other.usedCount == usedCount &&
        other.revoked == revoked &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(
    code,
    tripId,
    createdBy,
    maxUses,
    usedCount,
    revoked,
    createdAt,
    expiresAt,
  );

  @override
  String toString() => 'Invite($code for $tripId)';
}
