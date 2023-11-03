import 'package:dio/dio.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/features/video_chat/data/data_sources/remote/agora_apis.dart';
import 'package:vocechat_client/features/video_chat/data/models/agora_basic_info.dart';
import 'package:vocechat_client/features/video_chat/domain/repository/agora_repo.dart';

class AgoraRepoImpl implements AgoraRepository {
  final _agoraApis = AgoraApis();

  AgoraRepoImpl();

  /// Get Agora basic info, including token, uid, channel name, etc,
  ///
  /// The retrieved data is used to initialize Agora RTC engine and join channel.
  ///
  /// [uid] or [gid] is the target user/group that I want to chat with.
  ///
  /// Must check if Agora is enabled [isAgoraEnabled] in the server before calling this method.
  @override
  Future<DataState<AgoraBasicInfoModel>> getAgoraBasicInfo(
      {int? uid, int? gid}) async {
    try {
      final res = await _agoraApis.getAgoraBasicInfo(uid: uid, gid: gid);
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as AgoraBasicInfoModel;
        return DataSuccess(data);
      } else {
        return DataFailed(DioException(
            error: res.statusMessage,
            response: res,
            type: DioExceptionType.badResponse,
            requestOptions: res.requestOptions));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  /// Check if Agora is enabled in the server.
  Future<bool> isAgoraEnabled() async {
    try {
      return (await _agoraApis.isAgoraEnabled).data ?? false;
    } catch (e) {
      App.logger.info("Agora is not enabled in this server.");
      return false;
    }
  }
}
