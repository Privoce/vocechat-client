import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/feature/avchat/logic/avchat_api.dart';
import 'package:vocechat_client/feature/avchat/model/agora_token_info.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_events.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_states.dart';

class AvchatBloc extends Bloc<AvchatEvent, AvchatState> {
  final isVideoCall = false;

  UserInfoM? userInfoM;
  int? gid;

  bool get isOneToOneCall => userInfoM != null;
  bool get isGroupChat => gid != null;

  final _api = AvchatApi();

  RtcEngine? _agoraEngine;
  AgoraTokenInfo? _agoraTokenInfo;

  Timer? _chatTimer;

  List<UserInfoM> _guests = [];

  // TODO: microphone, camera, speaker state.

  AvchatBloc() : super(AvchatAvailabilityInitialState()) {
    on<AvchatInitRequest>(_onInitialRequest);
    on<AvchatAvailabilityCheckRequest>(_onAvailabilityCheckRequest);
    on<AvchatTokenInfoRequest>(_onTokenInfoRequest);
    on<AvchatPermissionCheckRequest>(_onAvchatPermissionCheckRequest);
    on<AvchatEngineInitRequest>(_onAvchatEngineInitRequest);
    on<AvchatJoinRequest>(_onAvchatJoinRequest);
    on<AvchatLocalInitRequest>(_onLocalInitRequest);
    on<AvchatSelfJoinedEvent>(_onSelfJoined);
    on<AvchatRemoteJoinedEvent>(_onRemoteJoined);
    on<AvchatUserOfflineEvent>(_onUserOffline);
    on<AvchatTimerUpdate>(_onTimerUpdate);
    on<AvchatMicBtnPressed>(_onMicBtnPressed);
    on<AvchatSpeakerBtnPressed>(_onSpeakerBtnPressed);
    on<AvchatEndCallBtnPressed>(_onAvchatLeaveRequest);
  }

  Future<void> _onInitialRequest(
      AvchatInitRequest event, Emitter<AvchatState> emit) async {
    userInfoM = event.userInfoM;
    gid = event.gid;
    add(AvchatAvailabilityCheckRequest());
  }

  Future<void> _onAvailabilityCheckRequest(
      AvchatAvailabilityCheckRequest event, Emitter<AvchatState> emit) async {
    emit(CheckingAvchatAvailability());
    try {
      final isEnabled = await _api.isAgoraEnabled();
      if (isEnabled) {
        emit(AvchatAvailable());
        App.logger.info("Agora is enabled at server side");
        add(AvchatTokenInfoRequest());
      } else {
        emit(AvchatUnavailable(message: "Agora is not enabled"));

        // should dispose the chat page. This will be handled in UI.
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AvchatAvailabilityCheckFail(e));
      // should dispose the chat page. This will be handled in UI.s
    }
  }

  Future<void> _onTokenInfoRequest(
      AvchatTokenInfoRequest event, Emitter<AvchatState> emit) async {
    try {
      final tokenInfo =
          await _api.getAgoraTokenInfo(uid: userInfoM!.uid, gid: gid);
      if (tokenInfo != null) {
        _agoraTokenInfo = tokenInfo;
        emit(AvchatTokenInfoReceived(tokenInfo));
        App.logger.info("Agora token info received.}");

        add(AvchatPermissionCheckRequest());
      } else {
        emit(AvchatTokenInfoFail("Failed to get agora token info"));
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AvchatTokenInfoFail(e));
    }
  }

  Future<void> _onAvchatPermissionCheckRequest(
      AvchatPermissionCheckRequest event, Emitter<AvchatState> emit) async {
    try {
      if (!isVideoCall) {
        final micStatus = await Permission.microphone.request();

        if (micStatus != PermissionStatus.granted) {
          emit(AvchatPermissionDisabled(
              isMicPermissionRequired: true,
              isCameraPermissionRequired: false));
          App.logger.info("Mic permission not granted");
        } else {
          emit(AvchatPermissionEnabled(isMicPermissionEnabled: true));
          App.logger.info("Mic permission granted");

          add(AvchatEngineInitRequest());
        }
      } else {
        final micStatus = await Permission.microphone.request();
        final camStatus = await Permission.camera.request();

        if (micStatus != PermissionStatus.granted ||
            camStatus != PermissionStatus.granted) {
          emit(AvchatPermissionDisabled(
              isMicPermissionRequired: micStatus != PermissionStatus.granted,
              isCameraPermissionRequired:
                  camStatus != PermissionStatus.granted));
          App.logger.info(
              "Mic or camera permission not granted: $micStatus, $camStatus");
        } else {
          emit(AvchatPermissionEnabled(
              isMicPermissionEnabled: true, isCameraPermissionEnabled: true));
          App.logger.info("Mic and camera permission granted");
          add(AvchatEngineInitRequest());
        }
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AvchatPermissionCheckFail(e));
    }
  }

  Future<void> _onAvchatEngineInitRequest(
      AvchatEngineInitRequest event, Emitter<AvchatState> emit) async {
    emit(AgoraInitializing());

    if (_agoraTokenInfo == null) {
      emit(AgoraInitFail("Agora token info is null"));
      App.logger.info("Agora token info is null");

      return;
    }

    try {
      _agoraEngine = createAgoraRtcEngine();

      await _agoraEngine?.initialize(RtcEngineContext(
          appId: _agoraTokenInfo!.appId,
          channelProfile: isOneToOneCall
              ? ChannelProfileType.channelProfileCommunication
              : ChannelProfileType.channelProfileLiveBroadcasting));

      emit(AgoraInitialized());
      App.logger.info("Agora engine initialized");

      add(AvchatJoinRequest());
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraInitFail(e));
    }
  }

  Future<void> _onAvchatJoinRequest(
      AvchatJoinRequest event, Emitter<AvchatState> emit) async {
    if (_agoraEngine == null || _agoraTokenInfo == null) {
      emit(AgoraSelfJoinFail("Agora engine or token info is null"));
      return;
    }
    try {
      emit(AgoraJoiningChannel());
      if (isVideoCall) {
        // await _agoraEngine?.enableVideo();
      } else {
        await _agoraEngine?.joinChannel(
            token: _agoraTokenInfo!.agoraToken,
            channelId: _agoraTokenInfo!.channelName,
            uid: _agoraTokenInfo!.uid,
            options: ChannelMediaOptions(
                clientRoleType: ClientRoleType.clientRoleBroadcaster));

        add(AvchatLocalInitRequest());
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraSelfJoinFail(e));
    }
  }

  Future<void> _onLocalInitRequest(
      AvchatLocalInitRequest event, Emitter<AvchatState> emit) async {
    if (_agoraEngine == null) {
      emit(AgoraSelfJoinFail("Agora engine is null"));
      return;
    }

    try {
      _agoraEngine?.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) async {
          add(AvchatSelfJoinedEvent());
        },
        onUserJoined: (connection, remoteUid, elapsed) async {
          add(AvchatRemoteJoinedEvent(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) async {
          add(AvchatUserOfflineEvent(remoteUid, reason));
        },
        onUserMuteAudio: (connection, remoteUid, muted) async {
          // add(AvchatMicBtnPressed());
          print("onUserMuteAudio: $remoteUid, $muted");
        },
      ));
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraCallingFail(e));
    }
  }

  void _onSelfJoined(
      AvchatSelfJoinedEvent event, Emitter<AvchatState> emit) async {
    emit(AgoraSelfJoined());

    if (isOneToOneCall && _guests.isEmpty) {
      emit(AgoraWaitingForPeer());
    }
    App.logger.info("Agora channel joined");
  }

  void _onRemoteJoined(
      AvchatRemoteJoinedEvent event, Emitter<AvchatState> emit) async {
    final remoteUid = event.uid;
    App.logger.info("Agora user joined: $remoteUid");

    try {
      final userInfoM = await UserInfoDao().getUserByUid(remoteUid);
      if (userInfoM == null) {
        App.logger.warning("User info not found, uid: $remoteUid");
        emit(AgoraCallingFail("User info not found, uid: $remoteUid"));
      } else {
        _guests.add(userInfoM);
        emit(AgoraGuestJoined(userInfoM));
        App.logger.info("Agora guest joined: ${userInfoM.uid}");

        if (isOneToOneCall) {
          _startTimer();
        }
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraCallingFail(e));
    }
  }

  void _onUserOffline(
      AvchatUserOfflineEvent event, Emitter<AvchatState> emit) async {
    final remoteUid = event.uid;
    final reason = event.reason;

    App.logger.info("Agora user left: $remoteUid due to $reason");

    try {
      final userInfoM = await UserInfoDao().getUserByUid(remoteUid);
      if (userInfoM == null) {
        emit(AgoraCallingFail("User info not found, uid: $remoteUid"));
      } else {
        _guests.remove(userInfoM);
        emit(AgoraGuestJoined(userInfoM));
        App.logger.info("Agora guest left: ${userInfoM.uid}");
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraCallingFail(e));
    }
  }

  Future<void> _onTimerUpdate(
      AvchatTimerUpdate event, Emitter<AvchatState> emit) async {
    emit(AgoraCallOnGoing(event.seconds));
  }

  Future<void> _onAvchatLeaveRequest(
      AvchatEndCallBtnPressed event, Emitter<AvchatState> emit) async {
    if (_agoraEngine == null) {
      emit(AgoraLeaveFail("Agora engine is null"));
      return;
    }

    try {
      await _clear();

      App.logger.info("Agora channel left; engine released");
      emit(AgoraLeftChannel());
      emit(AvchatAvailabilityInitialState());
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraLeaveFail(e));
      emit(AvchatAvailabilityInitialState());

      await _clear();
    }
  }

  void _onMicBtnPressed(
      AvchatMicBtnPressed event, Emitter<AvchatState> emit) async {
    final toMute = event.toMute;
    emit(AvchatMicBtnState(toMute));
    await _agoraEngine?.muteLocalAudioStream(toMute);
  }

  void _onSpeakerBtnPressed(
      AvchatSpeakerBtnPressed event, Emitter<AvchatState> emit) async {
    final toMute = event.toMute;
    emit(AvchatSpeakerBtnState(toMute));
    await _agoraEngine?.muteAllRemoteAudioStreams(toMute);
  }

  void _startTimer() {
    _chatTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      add(AvchatTimerUpdate(timer.tick));
    });
  }

  Future<void> _clear() async {
    await _agoraEngine?.leaveChannel();
    await _agoraEngine?.release();
    _chatTimer?.cancel();
    _chatTimer = null;
    userInfoM = null;
    gid = null;

    _guests.clear();
  }
}
