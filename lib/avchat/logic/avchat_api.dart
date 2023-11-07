import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/avchat/model/agora_basic_info.dart';
import 'package:vocechat_client/resource/exceptions/api_exception.dart';
import 'package:vocechat_client/resource/exceptions/unexpected_exception.dart';

class AvchatApi {
  late final String _baseUrl;

  AvchatApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/system";
  }

  Future<bool> isAgoraEnabled() async {
    try {
      final dio = DioUtil(baseUrl: _baseUrl);
      final res = await dio.get("/agora/enable");

      if (res.statusCode == 200 && res.data != null) {
        return res.data;
      }
    } catch (e) {
      if (e is DioException) {
        throw ApiException(dioException: e);
      }
      throw UnexpectedException(error: e);
    }

    return false;
  }

  /// Generates an agora token, together with some basic info.
  ///
  /// Data model is defined in [AgoraBasicInfo]
  ///
  /// Must provide either [uid] or [gid], but not both.
  /// Must check availability first, using [isAgoraEnabled].
  Future<AgoraBasicInfo?> getAgoraToken({int? uid, int? gid}) async {
    if (!((uid != null) ^ (gid != null))) {
      throw ArgumentError();
    }

    try {
      final dio = DioUtil.token(baseUrl: _baseUrl);
      final res = await dio
          .post("/agora/token", queryParameters: {"uid": uid, "gid": gid});

      if (res.statusCode == 200 && res.data != null) {
        return AgoraBasicInfo.fromJson(res.data);
      }
    } catch (e) {
      if (e is DioException) {
        throw ApiException(dioException: e);
      }
      throw UnexpectedException(error: e);
    }

    return null;
  }
}
