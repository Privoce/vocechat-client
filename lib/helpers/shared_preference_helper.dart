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
}
