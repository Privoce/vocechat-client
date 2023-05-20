import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static final SharedPreferenceHelper _helper =
      SharedPreferenceHelper._internal();

  factory SharedPreferenceHelper() {
    return _helper;
  }

  SharedPreferenceHelper._internal();

  static bool setShareExtensionData() {
    return true;
  }

  static Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
