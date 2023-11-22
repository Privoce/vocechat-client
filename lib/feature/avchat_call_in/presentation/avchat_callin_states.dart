import 'package:equatable/equatable.dart';
import 'package:vocechat_client/feature/avchat_call_in/model/agora_channel.dart';

abstract class AvchatCallInState extends Equatable {}

class AvchatCallInInitialState extends AvchatCallInState {
  @override
  List<Object?> get props => [];
}

/// Do not trigger any full screen chat UI, as call-in & calling cannot
/// be distinguished from backend data.
///
/// Now only show dialogs that have calls in progress.
class AvchatCallInOngoing extends AvchatCallInState {
  final AgoraChannel channel;

  AvchatCallInOngoing(this.channel);

  @override
  List<Object?> get props => [channel];
}
