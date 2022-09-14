import 'package:shared_preferences/shared_preferences.dart';

class SpUtils {
  static void setValue(String key, Object? value) {
    if (value is int) {
      setInt(key, value);
    } else if (value is bool) {
      setBool(key, value);
    } else if (value is double) {
      setDouble(key, value);
    } else if (value is String) {
      setString(key, value);
    } else if (value is List<String>) {
      setStringList(key, value);
    }
  }

  static Future getValue<T>(String key, T defaultValue) async {
    if (defaultValue is int) {
      return getInt(key, defaultValue);
    } else if (defaultValue is double) {
      return getDouble(key, defaultValue);
    } else if (defaultValue is bool) {
      return getBool(key, defaultValue);
    } else if (defaultValue is String) {
      return getString(key, defaultValue);
    } else if (defaultValue is List<String>) {
      return getStringList(key);
    }
  }

  static void setInt(String key, int? value, [int defaultValue = 0]) async {
    var sp = await SharedPreferences.getInstance();
    sp.setInt(key, value ?? defaultValue);
  }

  static Future<int> getInt(String key, [int defaultValue = 0]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getInt(key) ?? defaultValue;
  }

  static Future<bool> setBool(String key, bool? value,
      [bool defaultValue = false]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setBool(key, value ?? defaultValue);
  }

  static Future<bool> getBool(String key, [bool defaultValue = false]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getBool(key) ?? defaultValue;
  }

  static Future<bool> setDouble(String key, double? value,
      [double defaultValue = 0.0]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setDouble(key, value ?? defaultValue);
  }

  static Future<double> getDouble(String key,
      [double defaultValue = 0.0]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getDouble(key) ?? defaultValue;
  }

  static Future<bool> setString(String key, String? value,
      [String defaultValue = '']) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setString(key, value ?? defaultValue);
  }

  static Future<String> getString(String key,
      [String defaultValue = 'false']) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getString(key) ?? defaultValue;
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setStringList(key, value);
  }

  static Future<List<String>> getStringList(String key) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getStringList(key) ?? List.empty();
  }

  static Future<bool> remove(String key) async {
    var sp = await SharedPreferences.getInstance();
    return sp.remove(key);
  }

  static Future<bool> clearAll() async {
    var sp = await SharedPreferences.getInstance();
    return sp.clear();
  }

  static Future<Set<String>> getKeys() async {
    var sp = await SharedPreferences.getInstance();
    return sp.getKeys();
  }

  static Future<bool> containsKey(String key) async {
    var sp = await SharedPreferences.getInstance();
    return sp.containsKey(key);
  }
}
