// store username and x-aio-key in user defaults

import 'package:shared_preferences/shared_preferences.dart';

class UserDefaultsRepository {
  static const String USERNAME = 'username';
  static const String KEY = 'key';

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(USERNAME, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USERNAME);
  }

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY, key);
  }

  static Future<String?> getKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
