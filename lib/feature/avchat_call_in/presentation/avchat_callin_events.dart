import 'package:equatable/equatable.dart';
import 'package:vocechat_client/feature/avchat_call_in/model/agora_channel_data.dart';

abstract class AvchatCallInEvent extends Equatable {
  const AvchatCallInEvent();
}

class AvchatCallInInit extends AvchatCallInEvent {
  @override
  List<Object?> get props => [];
}

class AvchatCallInEnableRequest extends AvchatCallInEvent {
  @override
  List<Object?> get props => [];
}

class AvchatCallInInfoReceived extends AvchatCallInEvent {
  final AgoraChannelData channelData;

  const AvchatCallInInfoReceived({required this.channelData});

  @override
  List<Object?> get props => [channelData];
}

class AgoraCallInReceivingFailEvent extends AvchatCallInEvent {
  final Object error;

  const AgoraCallInReceivingFailEvent({required this.error});

  @override
  List<Object?> get props => [error];
}
