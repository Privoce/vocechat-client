import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';

abstract class AgoraRepository {
  /// Check if Agora is enabled in the server.
  ///
  /// Should be called before any other Agora related methods.
  Future<bool> isAgoraEnabled();

  /// Get Agora basic info, including token, uid, channel name, etc,
  /// defined in [AgoraBasicInfoEntity].
  ///
  /// Should be implemented in data layer(repository).
  ///
  /// In implementation, use [AgoraBasicInfoModel] as it is the implementation
  /// model.
  ///
  /// [uid] or [gid] is the target user/group that I want to chat with.
  Future<DataState<AgoraBasicInfoEntity>> getAgoraBasicInfo(
      {int? uid, int? gid});

  // TODO: to be refined
  void askForAudioPermission();

  void askForVideoPermission();

  void initAgoraEngine();

  void joinChannel();

  void leaveAndRelease();
}
