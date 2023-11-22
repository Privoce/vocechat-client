import 'package:equatable/equatable.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

enum AvchatUserConnectionState {
  disconnected,
  connecting,
  connected,
}

enum AvchatUserAudioState {
  muted,
  unmuted,
}

class AvchatUser extends Equatable {
  final UserInfoM userInfoM;
  final AvchatUserConnectionState connectState;
  final AvchatUserAudioState audioState;
  final bool muted;

  const AvchatUser(
      {required this.userInfoM,
      required this.connectState,
      required this.audioState,
      required this.muted});

  AvchatUser copyWith(
      {UserInfoM? userInfoM,
      AvchatUserConnectionState? connectState,
      AvchatUserAudioState? audioState,
      bool? muted}) {
    return AvchatUser(
        userInfoM: userInfoM ?? this.userInfoM,
        connectState: connectState ?? this.connectState,
        audioState: audioState ?? this.audioState,
        muted: muted ?? this.muted);
  }

  @override
  List<Object?> get props => [userInfoM, muted];
}
