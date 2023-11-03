import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/features/video_chat/data/models/agora_basic_info.dart';

class AgoraApis {
  late final String _baseUrl;

  AgoraApis({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/agora";
  }

  Future<Response<bool>> get isAgoraEnabled async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final res = await dio.get("/enabled");

    var newRes = Response<bool>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as bool;
      newRes.data = data;
    }
    return newRes;
  }

  /// Get Agora basic info, including token, uid, channel name, etc,
  ///
  /// The retrieved data is used to initialize Agora RTC engine and join channel.
  ///
  /// [uid] or [gid] is the target user/group that I want to chat with.
  Future<Response<AgoraBasicInfoModel>> getAgoraBasicInfo(
      {int? uid, int? gid}) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final queryParameters = <String, dynamic>{};
    if (uid != null) {
      queryParameters.addAll({"uid": uid});
    }
    if (gid != null) {
      queryParameters.addAll({"gid": gid});
    }

    final res = await dio.get("/token", queryParameters: queryParameters);

    var newRes = Response<AgoraBasicInfoModel>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as AgoraBasicInfoModel;
      newRes.data = data;
    }
    return newRes;
  }
}
