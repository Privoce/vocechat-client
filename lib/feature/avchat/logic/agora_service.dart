import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/feature/avchat/logic/avchat_api.dart';
import 'package:vocechat_client/feature/avchat/model/agora_basic_info.dart';
import 'package:vocechat_client/feature/avchat/model/exceptions.dart';

class AgoraService {
  final int? uid;
  final int? gid;

  RtcEngine? _engine;

  AgoraService({this.uid, this.gid}) {
    assert((uid != null) ^ (gid != null));
  }

  final AvchatApi _api = AvchatApi();

  Future<bool> checkAvailability() async {
    return _api.isAgoraEnabled();
  }

  Future<AgoraBasicInfo?> getAgoraBasicInfo() async {
    return _api.getAgoraToken(uid: uid, gid: gid);
  }

  /// Only include audio (microphone) permission request.
  Future<void> _askForAudioCallPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Permission denied");
    }
  }

  /// Include both audio (microphone) and video (camera) permission request.
  Future<void> _askForVideoCallPermission() async {
    await _askForAudioCallPermission();
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Permission denied");
    }
  }

  /// Create and init agora engine.
  ///
  /// Throws [AvchatEngineInitException] if failed to init/create agora engine.
  Future<void> _initAgoraEngine(
      AgoraBasicInfo basicInfo, bool isGroupChat) async {
    try {
      _engine = createAgoraRtcEngine();

      if (_engine == null) {
        throw AvchatEngineInitException("Failed to create agora engine");
      }

      await _engine?.initialize(RtcEngineContext(
        appId: basicInfo.appId,
        channelProfile: isGroupChat
            ? ChannelProfileType.channelProfileLiveBroadcasting
            : ChannelProfileType.channelProfileCommunication,
      ));
    } catch (e) {
      throw AvchatEngineInitException("Failed to init agora engine");
    }
  }

  /// This channel is not the VoceChat channel, but the agora channel, basically
  /// a chat room.
  Future<void> _joinChannel(
      AgoraBasicInfo basicInfo, bool isGroupChat, bool enableVideo) async {
    try {
      await _engine?.joinChannel(
          token: basicInfo.agoraToken,
          channelId: basicInfo.channelName,
          uid: basicInfo.uid,
          options: ChannelMediaOptions(
              clientRoleType: ClientRoleType.clientRoleBroadcaster));
      await _subscribeEventHandlers();
    } catch (e) {
      throw AvchatEngineInitException("Failed to join channel");
    }
  }

  Future<void> _subscribeEventHandlers() async {
    if (_engine == null) {
      return;
    }
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        // 成功加入频道回调
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          App.logger.info("local user ${connection.localUid} joined");
        },
        // 远端用户加入频道回调
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          App.logger.info("remote user $remoteUid joined");
        },
        // 远端用户离开频道回调
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          App.logger.info("remote user $remoteUid left channel");
        },
      ),
    );
  }

  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
  }
}
