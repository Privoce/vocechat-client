import 'package:equatable/equatable.dart';
import 'package:vocechat_client/feature/avchat_call_in/model/agora_channel.dart';

abstract class AvchatCallInState extends Equatable {}

class AvchatCallInInitialState extends AvchatCallInState {
  @override
  List<Object?> get props => [];
}

class AvchatCallEnabled extends AvchatCallInState {
  final bool enabled;

  AvchatCallEnabled({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class AgoraCallinReceivingFailed extends AvchatCallInState {
  final Object error;

  AgoraCallinReceivingFailed({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Do not trigger any full screen chat UI, as call-in & calling cannot
/// be distinguished from backend data.
///
/// Now only show dialogs that have calls in progress.
class AvchatOngoingCalls extends AvchatCallInState {
  final List<int> uids;
  final List<int> gids;

  AvchatOngoingCalls({required this.uids, required this.gids});

  @override
  List<Object?> get props => [uids, gids];
}
