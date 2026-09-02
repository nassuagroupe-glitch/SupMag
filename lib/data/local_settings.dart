import 'package:shared_preferences/shared_preferences.dart';

/// Per-terminal preferences — which store this device/till is currently
/// pointed at, which Caisse layout it defaults to, and its offline toggle.
/// These must NOT live in Firestore: they describe this one device, not
/// shared business data, so syncing them would make one cashier's screen
/// choice leak onto every other terminal.
class LocalSettings {
  LocalSettings();

  /// Swappable for tests — reassign to a fresh `LocalSettings()` between
  /// tests (alongside resetting shared_preferences' own mock values) so one
  /// test's store/variant/offline choice can't leak into the next.
  static LocalSettings instance = LocalSettings();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  Future<String?> getString(String key) async => (await _p).getString(key);

  Future<void> setString(String key, String value) async {
    await (await _p).setString(key, value);
  }
}
