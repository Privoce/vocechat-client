class UnexpectedException implements Exception {
  final Object? error;
  final String message;

  UnexpectedException(
      {this.error, this.message = "Some unexpected exception occurred"});
}
