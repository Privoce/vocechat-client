// /// Fill this variable with pre-defined server url.
// ///
// /// App will not ask for server url if this parameter is set.
// /// App will also disable multi-server switching if this parameter is set.
// String? appServerUrl = "https://dev.voce.chat:443";

abstract class EnvConstants {
  static const String voceBaseUrl =
      String.fromEnvironment('VOCE_BASE_URL', defaultValue: '');
}
