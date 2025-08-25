import 'package:shared_preferences/shared_preferences.dart';

class SpUtil {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return _prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _prefs.getBool(key) ?? defaultValue;
  }

  static Future<bool> setInt(String key, int value) async {
    return _prefs.setInt(key, value);
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    return _prefs.getInt(key) ?? defaultValue;
  }

  static Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  static Future<String> getString(String key,
      {String defaultValue = ''}) async {
    return _prefs.getString(key) ?? defaultValue;
  }

  static Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }
}
