import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

class OneToOneCallParams {
  final UserInfoM userInfoM;
  final bool isVideoCall;

  OneToOneCallParams({required this.userInfoM, required this.isVideoCall});
}

class GroupCallParams {
  final int gid;
  final bool isVideoCall;

  GroupCallParams({required this.gid, required this.isVideoCall});
}

abstract class AvchatEvent {}

class AvchatInitRequest extends AvchatEvent {
  final BuildContext context;
  final OneToOneCallParams? oneToOneCallParams;
  final GroupCallParams? groupCallParams;

  bool get isOneToOneCall => (oneToOneCallParams != null);

  AvchatInitRequest(
      {required this.context, this.oneToOneCallParams, this.groupCallParams}) {
    assert((oneToOneCallParams != null) ^ (groupCallParams != null));
  }
}

// ------------------ Bloc Events ------------------ //

class AvchatAvailabilityCheckRequest extends AvchatEvent {}

class AvchatTokenInfoRequest extends AvchatEvent {}

class AvchatPermissionCheckRequest extends AvchatEvent {}

class AvchatEngineInitRequest extends AvchatEvent {}

class AvchatJoinRequest extends AvchatEvent {}

class AvchatLocalInitRequest extends AvchatEvent {}

class AvchatSelfJoinedEvent extends AvchatEvent {}

class AvchatUserOfflineEvent extends AvchatEvent {
  final int uid;
  final UserOfflineReasonType reason;

  AvchatUserOfflineEvent(this.uid, this.reason);
}

class AvchatRemoteJoinedEvent extends AvchatEvent {
  final int uid;

  AvchatRemoteJoinedEvent(this.uid);
}

class AvchatTimerUpdate extends AvchatEvent {
  final int seconds;

  AvchatTimerUpdate(this.seconds);
}

// ------------------ UI Events ------------------ //
class AvchatCamBtnPressed extends AvchatEvent {}

class AvchatSpeakerBtnPressed extends AvchatEvent {
  final bool toMute;

  AvchatSpeakerBtnPressed(this.toMute);
}

class AvchatMicBtnPressed extends AvchatEvent {
  final bool toMute;

  AvchatMicBtnPressed(this.toMute);
}

class AvchatEndCallBtnPressed extends AvchatEvent {}

class AvchatMinimizeRequest extends AvchatEvent {
  final bool toMinimize;
  final BuildContext context;

  AvchatMinimizeRequest({required this.toMinimize, required this.context});
}

class AvchatEnableButtonRequest extends AvchatEvent {
  final bool toEnable;

  AvchatEnableButtonRequest(this.toEnable);
}

// ------------------ AvchatUserBloc ------------------ //
class AvchatUserChanged extends AvchatEvent {
  final int uid;
  final bool muted;

  AvchatUserChanged({required this.uid, required this.muted});
}
