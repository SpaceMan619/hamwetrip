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
///
/// This document is the **only** record of membership — see [Trip] for why the
/// denormalized array on the trip was removed.
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
    this.joinedWithCode,
  });

  /// The member's uid, and the document id.
  ///
  /// Also written into the document body, which looks redundant but is load
  /// bearing: `watchMyTrips()` runs
  /// `collectionGroup('members').where('uid', isEqualTo: me)`, and a collection
  /// group query can only filter on fields, never on document ids. The matching
  /// security rule tests the same field, so the query constraint and the rule
  /// are provably the same condition.
  final String uid;

  /// Owning trip. Not stored in the document — it is implied by the path — but
  /// carried on the model so a member can be passed around without its parent.
  final String tripId;

  final TripRole role;

  /// Denormalized from `users/{uid}` so a member list renders in one read
  /// instead of N.
  ///
  /// This is also the *only* way anyone learns another person's name:
  /// `users/{uid}` is owner-read-only, so trip-mates never read each other's
  /// profile documents. Kept fresh by the client on profile edit.
  final String displayName;
  final String? photoUrl;

  final DateTime? joinedAt;

  /// The invite code this membership was created with.
  ///
  /// Stored so the security rule can `get()` that invite and confirm it points
  /// at this trip and is neither expired, revoked nor exhausted. Without Cloud
  /// Functions the joining client writes its own membership document, so this
  /// field is what makes that write verifiable rather than forgeable.
  ///
  /// Null for the organizer who created the trip, who joined no invite.
  final String? joinedWithCode;

  /// Denormalized net position in minor units: positive means the trip owes
  /// this member, negative means they owe the trip.
  ///
  /// Phase 2 still owns the decision (P2-6) of how balances are computed.
  /// Nullable so both outcomes are representable: null means "never computed",
  /// not "settled to zero".
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
      // The document id wins over the stored field. They should always agree —
      // the rule enforces it on write — but the path is authoritative.
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
      joinedWithCode: parseOptionalString(data['joinedWithCode']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'uid': uid,
      'role': role.wire,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'joinedAt': writeDateTime(joinedAt),
      'balanceMinor': balanceMinor,
      'joinedWithCode': joinedWithCode,
    };
  }

  TripMember copyWith({
    TripRole? role,
    String? displayName,
    String? photoUrl,
    DateTime? joinedAt,
    int? balanceMinor,
    String? joinedWithCode,
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
      joinedWithCode: joinedWithCode ?? this.joinedWithCode,
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
        other.balanceMinor == balanceMinor &&
        other.joinedWithCode == joinedWithCode;
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
    joinedWithCode,
  );

  @override
  String toString() => 'TripMember($uid in $tripId as ${role.wire})';
}
