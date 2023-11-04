import 'package:dio/dio.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/features/video_chat/data/data_sources/remote/agora_apis.dart';
import 'package:vocechat_client/features/video_chat/data/models/agora_basic_info.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_error.dart';
import 'package:vocechat_client/features/video_chat/domain/repository/agora_repo.dart';

class AgoraRepoImpl implements AgoraRepository {
  final _agoraApis = AgoraApis();

  AgoraRepoImpl();

  /// Check if Agora is enabled in the server.
  ///
  /// Should be called before any other Agora related methods.
  @override
  Future<bool> isAgoraEnabled() async {
    try {
      return (await _agoraApis.isAgoraEnabled).data ?? false;
    } catch (e) {
      App.logger.info("Agora is not enabled in this server.");
      return false;
    }
  }

  /// Get Agora basic info, including token, uid, channel name, etc,
  ///
  /// The retrieved data is used to initialize Agora RTC engine and join channel.
  ///
  /// [uid] or [gid] is the target user/group that I want to chat with.
  ///
  /// [isAgoraEnabled] has been included into this method to avoid further
  /// callings to uninitialized servers. [InternalError] will be returned with
  /// messages in String.

  @override
  Future<DataState<AgoraBasicInfoModel>> getAgoraBasicInfo(
      {int? uid, int? gid}) async {
    try {
      if (!(await isAgoraEnabled())) {
        return DataFailed.error(
            AgoraNotEnabledError("Agora is not enabled in this server."));
      }

      if ((uid == null && gid == null) || (uid != null && gid != null)) {
        return DataFailed.error(
            VideoChatError("only one of uid or gid should be provided."));
      }

      final res = await _agoraApis.getAgoraBasicInfo(uid: uid, gid: gid);
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as AgoraBasicInfoModel;
        return DataSuccess(data);
      } else {
        return DataFailed.network(DioException(
            error: res.statusMessage,
            response: res,
            type: DioExceptionType.badResponse,
            requestOptions: res.requestOptions));
      }
    } on DioException catch (e) {
      return DataFailed.network(e);
    } catch (e) {
      return DataFailed.error(VideoChatError(e.toString()));
    }
  }
}
