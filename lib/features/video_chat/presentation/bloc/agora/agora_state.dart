import 'package:equatable/equatable.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_error.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';

abstract class AgoraState extends Equatable {
  final AgoraBasicInfoEntity? agoraBasicInfo;
  final VideoChatError? error;

  const AgoraState({this.agoraBasicInfo, this.error});

  @override
  List<Object?> get props => [agoraBasicInfo, error];
}

class AgoraConnecting extends AgoraState {
  const AgoraConnecting();
}

class AgoraConnected extends AgoraState {
  // const AgoraConnected({required AgoraBasicInfoEntity agoraBasicInfo})
  //     : super(agoraBasicInfo: agoraBasicInfo);
  const AgoraConnected();
}

class AgoraError extends AgoraState {
  const AgoraError({required VideoChatError error}) : super(error: error);
}
