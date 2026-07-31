import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings that belong to this device rather than to the account.
///
/// Firestore holds everything the group shares. These three are different:
/// they describe how this particular installation behaves, they should survive
/// a restart, and they should be readable before the network is, so the app can
/// decide what to show on the very first frame.
///
/// Kept behind one class rather than scattering `SharedPreferences` calls
/// through the widgets, so the key names live in a single place and cannot
/// drift apart.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const _keyLastOpenedTripId = 'lastOpenedTripId';
  static const _keyNotificationsEnabled = 'notificationsEnabled';

  /// Whether the onboarding pages have been completed or skipped.
  ///
  /// Read synchronously while choosing the first route, which is why the
  /// instance is loaded before `runApp` rather than awaited inside a widget.
  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_keyHasSeenOnboarding, value);

  /// The trip this device last opened, so returning to the app lands where the
  /// member left off instead of on a generic list.
  ///
  /// Null when they have not opened one yet. Cleared on sign out, since the
  /// next person to use the device may not be a member of that trip.
  String? get lastOpenedTripId {
    final id = _prefs.getString(_keyLastOpenedTripId);
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> setLastOpenedTripId(String tripId) =>
      _prefs.setString(_keyLastOpenedTripId, tripId);

  Future<void> clearLastOpenedTripId() => _prefs.remove(_keyLastOpenedTripId);

  /// Local copy of the push notification preference.
  ///
  /// The account's setting still lives in `users/{uid}`; this mirror exists so
  /// the profile screen shows the right position of the switch immediately on
  /// launch, including offline, rather than flicking to the stored value once
  /// Firestore answers. Defaults to on, matching the profile document.
  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyNotificationsEnabled, value);

  /// Forgets the device-scoped settings that belong to whoever was signed in.
  ///
  /// [hasSeenOnboarding] deliberately survives: onboarding explains the app,
  /// not the account, so a second user on the same device should not be shown
  /// it again.
  Future<void> clearForSignOut() async {
    await clearLastOpenedTripId();
    await _prefs.remove(_keyNotificationsEnabled);
  }
}

/// Overridden in `main` with the instance loaded before the app starts.
///
/// Throwing by default is intentional: a silent fallback would let a missing
/// override reach production as preferences that quietly never persist.
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError(
    'appPreferencesProvider must be overridden with a loaded AppPreferences. '
    'See main.dart.',
  );
});
