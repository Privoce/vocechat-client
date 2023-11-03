import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';

abstract class AgoraRepository {
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
}
