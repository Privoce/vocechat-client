class VideoChatError extends Error {
  final String errorMessage;

  VideoChatError(this.errorMessage);
}

class AgoraInitializationError extends VideoChatError {
  AgoraInitializationError(String errorMessage) : super(errorMessage);
}

class AgoraNotEnabledError extends VideoChatError {
  AgoraNotEnabledError(String errorMessage) : super(errorMessage);
}

class AgoraPermissionError extends VideoChatError {
  bool isCameraPermissionError = false;
  bool isMicrophonePermissionError = false;

  AgoraPermissionError(
      {String errorMessage = "",
      this.isCameraPermissionError = false,
      this.isMicrophonePermissionError = false})
      : super(errorMessage);
}
