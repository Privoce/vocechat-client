import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/feature/avchat/logic/avchat_api.dart';
import 'package:vocechat_client/feature/avchat/model/agora_token_info.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_events.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_states.dart';

class AvchatBloc extends Bloc<AvchatEvent, AvchatState> {
  bool isVideoCall = false;

  final int? uid;
  final int? gid;

  bool get isOneToOneCall => uid != null;
  bool get isGroupChat => gid != null;

  final _api = AvchatApi();

  RtcEngine? _agoraEngine;
  AgoraTokenInfo? _agoraTokenInfo;

  AvchatBloc({required this.isVideoCall, this.uid, this.gid})
      : super(AvchatAvailabilityInitialState()) {
    assert((uid != null) ^ (gid != null));

    on<AvchatAvailabilityCheckRequest>(_onAvailabilityCheckRequest);
    on<AvchatTokenInfoRequest>(_onTokenInfoRequest);
    on<AvchatPermissionCheckRequest>(_onAvchatPermissionCheckRequest);
    on<AvchatEngineInitRequest>(_onAvchatEngineInitRequest);
    on<AvchatJoinRequest>(_onAvchatJoinRequest);
    on<AvchatLeaveRequest>(_onAvchatLeaveRequest);
  }

  Future<void> _onAvailabilityCheckRequest(
      AvchatAvailabilityCheckRequest event, Emitter<AvchatState> emit) async {
    emit(CheckingAvchatAvailability());
    try {
      final isEnabled = await _api.isAgoraEnabled();
      if (isEnabled) {
        emit(AvchatAvailable());
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
      final tokenInfo = await _api.getAgoraTokenInfo(uid: uid, gid: gid);
      if (tokenInfo != null) {
        _agoraTokenInfo = tokenInfo;
        emit(AvchatTokenInfoReceived(tokenInfo));
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
        } else {
          emit(AvchatPermissionEnabled(isMicPermissionEnabled: true));
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
        } else {
          emit(AvchatPermissionEnabled(
              isMicPermissionEnabled: true, isCameraPermissionEnabled: true));
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
      return;
    }

    try {
      _agoraEngine = createAgoraRtcEngine();

      await _agoraEngine?.initialize(RtcEngineContext(
          appId: _agoraTokenInfo!.appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting));

      emit(AgoraInitialized());
      add(AvchatJoinRequest());
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraInitFail(e));
    }
  }

  Future<void> _onAvchatJoinRequest(
      AvchatJoinRequest event, Emitter<AvchatState> emit) async {
    if (_agoraEngine == null || _agoraTokenInfo == null) {
      emit(AgoraJoinFail("Agora engine or token info is null"));
      return;
    }

    if (isVideoCall) {
      // await _agoraEngine?.enableVideo();
    } else {
      await _agoraEngine?.joinChannel(
          token: _agoraTokenInfo!.agoraToken,
          channelId: _agoraTokenInfo!.channelName,
          uid: _agoraTokenInfo!.uid,
          options: ChannelMediaOptions(
              clientRoleType: ClientRoleType.clientRoleBroadcaster));
    }
  }

  Future<void> _onAvchatLeaveRequest(
      AvchatLeaveRequest event, Emitter<AvchatState> emit) async {
    if (_agoraEngine == null) {
      emit(AgoraLeaveFail("Agora engine is null"));
      return;
    }

    try {
      await _agoraEngine?.leaveChannel();
      await _agoraEngine?.release();
      emit(AgoraLeftChannel());
    } catch (e) {
      App.logger.severe(e);
      emit(AgoraLeaveFail(e));
    }
  }
}
