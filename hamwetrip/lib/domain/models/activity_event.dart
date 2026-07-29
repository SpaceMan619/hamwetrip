import 'package:flutter/foundation.dart';

import '../../core/util/initials.dart';
import 'model_parsing.dart';

/// What kind of thing an activity event points at, so the feed knows which
/// screen to open when a row is tapped. Derived from [ActivityType] rather than
/// stored, because the two can never legitimately disagree.
enum ActivityEntityKind {
  trip,
  member,
  poll,
  expense,
  payment,
  itinerary,
  document,
  none,
}

/// Every event the activity feed can render.
///
/// The wire values marked below come straight from the delivery guide and must
/// not be changed — they are already the contract. The rest follow the same
/// snake_case convention.
enum ActivityType {
  tripCreated('trip_created', ActivityEntityKind.trip),
  memberJoined('member_joined', ActivityEntityKind.member),
  memberRemoved('member_removed', ActivityEntityKind.member),
  memberRoleChanged('member_role_changed', ActivityEntityKind.member),

  pollCreated('poll_created', ActivityEntityKind.poll),

  /// Specified by the delivery guide.
  voteCast('vote_cast', ActivityEntityKind.poll),

  /// Specified by the delivery guide.
  pollClosed('poll_closed', ActivityEntityKind.poll),

  /// Specified by the delivery guide.
  expenseAdded('expense_added', ActivityEntityKind.expense),
  expenseUpdated('expense_updated', ActivityEntityKind.expense),
  expenseDeleted('expense_deleted', ActivityEntityKind.expense),

  /// Specified by the delivery guide.
  paymentClaimed('payment_claimed', ActivityEntityKind.payment),

  /// Specified by the delivery guide.
  paymentConfirmed('payment_confirmed', ActivityEntityKind.payment),
  paymentRejected('payment_rejected', ActivityEntityKind.payment),

  itineraryUpdated('itinerary_updated', ActivityEntityKind.itinerary),

  /// Specified by the delivery guide.
  documentUploaded('document_uploaded', ActivityEntityKind.document),

  /// Specified by the delivery guide.
  documentDownloaded('document_downloaded', ActivityEntityKind.document),

  /// Forward-compatibility fallback. A build that predates a newly added event
  /// type renders the stored summary and simply does not deep-link.
  unknown('unknown', ActivityEntityKind.none);

  const ActivityType(this.wire, this.entityKind);

  final String wire;

  /// Which screen a tap on this event should open.
  final ActivityEntityKind entityKind;
}

/// One entry in a trip's audit trail. Mirrors `trips/{tripId}/activity/{eventId}`.
///
/// Written by the server (Cloud Functions) rather than by clients, so the feed
/// can be trusted and the security rule for this path is read-only to clients.
@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.tripId,
    required this.type,
    required this.actorId,
    required this.summary,
    this.actorName,
    this.entityId,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final ActivityType type;

  /// uid of whoever caused the event.
  final String actorId;

  /// Denormalized actor name so the feed renders without an extra read per row.
  /// Display-only; `users/{uid}` remains the source of truth.
  final String? actorName;

  /// Short server-authored sentence, already safe to render.
  ///
  /// Deliberately pre-rendered rather than composed on the client: an old build
  /// must still be able to display an event type it does not recognise.
  final String summary;

  /// Id of the poll, expense, payment, document or itinerary item this event
  /// refers to. Combined with [ActivityType.entityKind] it gives the feed
  /// everything it needs to deep-link.
  final String? entityId;

  final DateTime? createdAt;

  /// True while a local write is pending — relevant because the feed is ordered
  /// by [createdAt], and pending rows sort with a null key.
  bool get isPending => createdAt == null;

  /// Whether tapping this row can navigate anywhere.
  bool get canDeepLink =>
      entityId != null && type.entityKind != ActivityEntityKind.none;

  String get actorInitials =>
      actorName == null ? '?' : initialsFrom(actorName!);

  factory ActivityEvent.fromMap(
    String tripId,
    String id,
    Map<String, Object?> data,
  ) {
    return ActivityEvent(
      id: id,
      tripId: tripId,
      type: parseWireEnum(
        data['type'],
        ActivityType.values,
        (type) => type.wire,
        ActivityType.unknown,
      ),
      actorId: parseString(data['actorId']),
      actorName: parseOptionalString(data['actorName']),
      summary: parseString(data['summary']),
      entityId: parseOptionalString(data['entityId']),
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.wire,
      'actorId': actorId,
      'actorName': actorName,
      'summary': summary,
      'entityId': entityId,
      'createdAt': writeDateTime(createdAt),
    };
  }

  ActivityEvent copyWith({
    ActivityType? type,
    String? actorId,
    String? actorName,
    String? summary,
    String? entityId,
    DateTime? createdAt,
  }) {
    return ActivityEvent(
      id: id,
      tripId: tripId,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      summary: summary ?? this.summary,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityEvent &&
        other.id == id &&
        other.tripId == tripId &&
        other.type == type &&
        other.actorId == actorId &&
        other.actorName == actorName &&
        other.summary == summary &&
        other.entityId == entityId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    type,
    actorId,
    actorName,
    summary,
    entityId,
    createdAt,
  );

  @override
  String toString() => 'ActivityEvent($id, ${type.wire})';
}
