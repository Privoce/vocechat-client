class AvchatEngineInitException implements Exception {
  final String message;

  AvchatEngineInitException(this.message);

  @override
  String toString() {
    return 'AvchatEngineInitializeException: $message';
  }
}
