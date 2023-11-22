import 'package:equatable/equatable.dart';
import 'package:vocechat_client/feature/avchat_call_in/model/agora_channel_data.dart';

abstract class AvchatCallinEvent extends Equatable {
  const AvchatCallinEvent();
}

class AvchatCallinInit extends AvchatCallinEvent {
  @override
  List<Object?> get props => [];
}

class AvchatCallinEnableRequest extends AvchatCallinEvent {
  @override
  List<Object?> get props => [];
}

class AvchatCallinInfoReceived extends AvchatCallinEvent {
  final AgoraChannelData channelData;

  const AvchatCallinInfoReceived({required this.channelData});

  @override
  List<Object?> get props => [channelData];
}

class AgoraCallinReceivingFailEvent extends AvchatCallinEvent {
  final Object error;

  const AgoraCallinReceivingFailEvent({required this.error});

  @override
  List<Object?> get props => [error];
}
