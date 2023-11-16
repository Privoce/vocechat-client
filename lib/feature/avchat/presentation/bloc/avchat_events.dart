import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

abstract class AvchatEvent {}

class AvchatInitRequest extends AvchatEvent {
  final bool isVideoCall;
  // final int? uid;
  final UserInfoM? userInfoM;
  final int? gid;

  AvchatInitRequest({this.userInfoM, this.gid, required this.isVideoCall}) {
    assert((userInfoM != null) ^ (gid != null));
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
