import 'package:flutter/foundation.dart';

import 'model_parsing.dart';

/// Lifecycle of a trip. Mirrors the `status` field the delivery guide lists on
/// `trips/{tripId}` but does not enumerate — these are the agreed values.
enum TripStatus {
  /// Being planned. Polls and itinerary drafting happen here.
  planning('planning'),

  /// Currently under way.
  active('active'),

  /// Finished, but the ledger may still have outstanding settlements.
  completed('completed'),

  /// Hidden from the home feed. Read-only.
  archived('archived'),

  /// Forward-compatibility fallback for a value written by a newer client.
  unknown('unknown');

  const TripStatus(this.wire);

  /// Stable stored representation. Never derive this from [name].
  final String wire;
}

/// A trip. Mirrors `trips/{tripId}`.
///
/// All trip-owned data (members, polls, expenses, payments, itinerary,
/// documents, activity) lives in subcollections beneath this document, which is
/// what makes the security rules expressible and cleanup tractable.
///
/// ## Membership is not stored here
///
/// An earlier revision denormalized a `memberIds` array onto this document so
/// `watchMyTrips()` could be a single `arrayContains` query. That does not
/// survive without Cloud Functions: redeeming an invite would require someone
/// who is *not yet a member* to update this document, and no security rule can
/// safely permit that.
///
/// Membership now lives only in `trips/{tripId}/members/{uid}`, and
/// `watchMyTrips()` runs `collectionGroup('members').where('uid', ...)`. One
/// source of truth, and nothing to drift.
@immutable
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.ownerId,
    required this.currency,
    required this.status,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String destination;

  /// uid of the trip creator. Distinct from role: the owner is always an
  /// organizer, but a trip can have several organizers.
  final String ownerId;

  /// ISO 4217 code. `RWF` for the MVP — note RWF has **no minor unit**, so a
  /// stored amount of `5000` means RWF 5,000, not RWF 50.00.
  final String currency;

  final TripStatus status;

  /// Stored UTC. Convert to local only when rendering.
  final DateTime? startDate;
  final DateTime? endDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True until the server acknowledges the creating write.
  bool get isPending => createdAt == null;

  /// Whether the trip still accepts new polls, expenses and itinerary edits.
  bool get isEditable =>
      status == TripStatus.planning || status == TripStatus.active;

  factory Trip.fromMap(String id, Map<String, Object?> data) {
    return Trip(
      id: id,
      name: parseString(data['name']),
      destination: parseString(data['destination']),
      ownerId: parseString(data['ownerId']),
      currency: parseString(data['currency'], fallback: 'RWF'),
      status: parseWireEnum(
        data['status'],
        TripStatus.values,
        (status) => status.wire,
        TripStatus.unknown,
      ),
      startDate: parseDateTime(data['startDate']),
      endDate: parseDateTime(data['endDate']),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'destination': destination,
      'ownerId': ownerId,
      'currency': currency,
      'status': status.wire,
      'startDate': writeDateTime(startDate),
      'endDate': writeDateTime(endDate),
      'createdAt': writeDateTime(createdAt),
      'updatedAt': writeDateTime(updatedAt),
    };
  }

  Trip copyWith({
    String? name,
    String? destination,
    String? ownerId,
    String? currency,
    TripStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      ownerId: ownerId ?? this.ownerId,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Trip &&
        other.id == id &&
        other.name == name &&
        other.destination == destination &&
        other.ownerId == ownerId &&
        other.currency == currency &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    destination,
    ownerId,
    currency,
    status,
    startDate,
    endDate,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Trip($id, $name)';
}
