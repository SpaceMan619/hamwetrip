import 'package:flutter/foundation.dart';

import '../../core/util/initials.dart';
import 'model_parsing.dart';

/// A HamweTrip account. Mirrors `users/{uid}`.
///
/// Created atomically with the Firebase Auth account at sign-up. The document
/// id *is* the Firebase Auth uid — there is no separate user id anywhere in the
/// system, so every reference to a person (payer, voter, uploader) is a uid.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.createdAt,
    this.notificationsEnabled = true,
  });

  /// Firebase Auth uid, and the document id.
  final String uid;

  final String displayName;
  final String email;

  /// MoMo number. Optional — the sign-up form does not collect it, so it is
  /// filled in later from the profile screen, and settlement screens must
  /// handle its absence rather than assuming every member has one.
  final String? phone;

  final String? photoUrl;

  /// Null while a local write is still pending. See [parseDateTime].
  final DateTime? createdAt;

  /// Master switch for push notifications, honoured by the FCM triggers.
  final bool notificationsEnabled;

  /// Initials for avatar placeholders, derived rather than stored.
  String get initials => initialsFrom(displayName);

  /// True until the server acknowledges the creating write.
  bool get isPending => createdAt == null;

  factory AppUser.fromMap(String id, Map<String, Object?> data) {
    return AppUser(
      uid: id,
      displayName: parseString(data['displayName']),
      email: parseString(data['email']),
      phone: parseOptionalString(data['phone']),
      photoUrl: parseOptionalString(data['photoUrl']),
      createdAt: parseDateTime(data['createdAt']),
      notificationsEnabled: parseBool(
        data['notificationsEnabled'],
        fallback: true,
      ),
    );
  }

  /// The document body. The uid is the document id and is deliberately not
  /// duplicated inside the document.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': writeDateTime(createdAt),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
    bool? notificationsEnabled,
    bool clearPhone = false,
    bool clearPhotoUrl = false,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      createdAt: createdAt ?? this.createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppUser &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.phone == phone &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode => Object.hash(
    uid,
    displayName,
    email,
    phone,
    photoUrl,
    createdAt,
    notificationsEnabled,
  );

  @override
  String toString() => 'AppUser($uid, $displayName)';
}
