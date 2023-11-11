abstract class AvchatState {}

/// A general error states for all Agora related errors
class AgoraError extends AvchatState {
  final Error? error;
  final String? message;

  AgoraError({this.error, this.message});
}

// ------------------ AvchatAvailabilityCheckBloc ------------------ //
abstract class AvailabilityState extends AvchatState {}

class AvailabilityStateInitial extends AvailabilityState {}

class CheckingAvchatAvailability extends AvailabilityState {}

class AvchatAvailable extends AvailabilityState {}

class AvchatUnavailable extends AvailabilityState {
  final String? message;

  AvchatUnavailable({this.message});
}

class AvchatAvailabilityCheckError extends AgoraError {
  AvchatAvailabilityCheckError({super.error, super.message});
}

// ------------------ AvchatPermissionCheckBloc ------------------ //
abstract class AvchatPermissionState extends AvchatState {}

class AvchatPermissionEnabled extends AvchatPermissionState {
  final bool isMicPermissionEnabled;
  final bool isCameraPermissionEnabled;

  AvchatPermissionEnabled(
      {required this.isMicPermissionEnabled,
      required this.isCameraPermissionEnabled});
}

class AvchatPermissionDisabled extends AvchatPermissionState {
  final bool isMicPermissionRequired;
  final bool isCameraPermissionRequired;

  AvchatPermissionDisabled(
      {required this.isMicPermissionRequired,
      required this.isCameraPermissionRequired});
}

class AvchatPermissionCheckError extends AgoraError {
  AvchatPermissionCheckError({super.error, super.message});
}

// ------------------ AgoraInitBloc ------------------ //
class AgoraInitilizing extends AvchatState {}

class AgoraInitialized extends AvchatState {}

class AgoraInitError extends AgoraError {
  AgoraInitError({super.error, super.message});
}

// ------------------ AgoraJoinChannelBloc ------------------ //
class AgoraJoiningChannel extends AvchatState {}

class AgoraChannelJoined extends AvchatState {}

class AgoraJoinChannelError extends AgoraError {
  AgoraJoinChannelError({super.error, super.message});
}
