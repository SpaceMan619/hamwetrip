import 'package:flutter/foundation.dart';

import '../../core/util/initials.dart';
import 'model_parsing.dart';

/// What a member is allowed to do inside a trip.
///
/// [editor] exists because the delivery guide grants itinerary writes to
/// "organizer/editor" — without it, the itinerary rule cannot be expressed.
enum TripRole {
  /// Full control: trip settings, membership, closing polls, confirming
  /// settlements.
  organizer('organizer'),

  /// May write itinerary and trip content, but not manage membership or
  /// confirm payments.
  editor('editor'),

  /// Reads everything in the trip, creates expenses, votes.
  member('member'),

  /// Forward-compatibility fallback. Treated as the least privileged role.
  unknown('unknown');

  const TripRole(this.wire);

  final String wire;

  /// Permission helpers, kept on the role so screens and rules tests agree on
  /// one definition instead of each re-deriving it.
  bool get canManageMembership => this == TripRole.organizer;
  bool get canEditTripSettings => this == TripRole.organizer;
  bool get canConfirmPayments => this == TripRole.organizer;
  bool get canClosePolls => this == TripRole.organizer;
  bool get canEditItinerary =>
      this == TripRole.organizer || this == TripRole.editor;
}

/// Membership of one person in one trip. Mirrors `trips/{tripId}/members/{uid}`.
///
/// The document id is the member's uid, which makes "one membership per person
/// per trip" a property of the database rather than something the client has to
/// enforce.
@immutable
class TripMember {
  const TripMember({
    required this.uid,
    required this.tripId,
    required this.role,
    required this.displayName,
    this.photoUrl,
    this.joinedAt,
    this.balanceMinor,
  });

  /// The member's uid, and the document id.
  final String uid;

  /// Owning trip. Not stored in the document — it is implied by the path — but
  /// carried on the model so a member can be passed around without its parent.
  final String tripId;

  final TripRole role;

  /// Denormalized from `users/{uid}` so a member list renders in one read
  /// instead of N. Refreshed by a Cloud Function when the profile changes;
  /// treat it as display-only and never as the source of truth.
  final String displayName;
  final String? photoUrl;

  final DateTime? joinedAt;

  /// Denormalized net position in minor units: positive means the trip owes
  /// this member, negative means they owe the trip.
  ///
  /// The delivery guide lists `balanceSummary` on this document, but Phase 2
  /// still owns the decision (P2-6) of whether balances are computed on the
  /// client or maintained by a Cloud Function. Nullable so both outcomes are
  /// representable: null means "never computed", not "settled to zero".
  /// **Do not read this for settlement truth until P2-6 is resolved.**
  final int? balanceMinor;

  String get initials => initialsFrom(displayName);

  bool get isPending => joinedAt == null;

  factory TripMember.fromMap(
    String tripId,
    String uid,
    Map<String, Object?> data,
  ) {
    return TripMember(
      uid: uid,
      tripId: tripId,
      role: parseWireEnum(
        data['role'],
        TripRole.values,
        (role) => role.wire,
        TripRole.unknown,
      ),
      displayName: parseString(data['displayName']),
      photoUrl: parseOptionalString(data['photoUrl']),
      joinedAt: parseDateTime(data['joinedAt']),
      balanceMinor: parseOptionalInt(data['balanceMinor']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'role': role.wire,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'joinedAt': writeDateTime(joinedAt),
      'balanceMinor': balanceMinor,
    };
  }

  TripMember copyWith({
    TripRole? role,
    String? displayName,
    String? photoUrl,
    DateTime? joinedAt,
    int? balanceMinor,
    bool clearPhotoUrl = false,
    bool clearBalance = false,
  }) {
    return TripMember(
      uid: uid,
      tripId: tripId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      joinedAt: joinedAt ?? this.joinedAt,
      balanceMinor: clearBalance ? null : (balanceMinor ?? this.balanceMinor),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripMember &&
        other.uid == uid &&
        other.tripId == tripId &&
        other.role == role &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.joinedAt == joinedAt &&
        other.balanceMinor == balanceMinor;
  }

  @override
  int get hashCode => Object.hash(
    uid,
    tripId,
    role,
    displayName,
    photoUrl,
    joinedAt,
    balanceMinor,
  );

  @override
  String toString() => 'TripMember($uid in $tripId as ${role.wire})';
}
