import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/resource/exceptions/api_exception.dart';
import 'package:vocechat_client/resource/exceptions/unexpected_exception.dart';

import '../model/agora_channel_info.dart';
import '../model/agora_token_info.dart';

class AvchatApi {
  late final String _baseUrl;

  AvchatApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/agora";
  }

  Future<bool> isAgoraEnabled() async {
    try {
      final dio = DioUtil(baseUrl: _baseUrl);
      final res = await dio.get("/enabled");

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
  /// Data model is defined in [AgoraTokenInfo]
  ///
  /// Must provide either [uid] or [gid], but not both.
  /// Must check availability first, using [isAgoraEnabled].
  Future<AgoraTokenInfo?> getAgoraTokenInfo({int? uid, int? gid}) async {
    if (!((uid != null) ^ (gid != null))) {
      throw ArgumentError();
    }

    try {
      final dio = DioUtil.token(baseUrl: _baseUrl);
      final res = await dio.post("/token", data: {"uid": uid, "gid": gid});

      if (res.statusCode == 200 && res.data != null) {
        return AgoraTokenInfo.fromJson(res.data);
      }
    } catch (e) {
      if (e is DioException) {
        throw ApiException(dioException: e);
      }
      throw UnexpectedException(error: e);
    }

    return null;
  }

  Future<AgoraChannelInfo?> getChannels(
      {int pageNo = 0, int pageSize = 100}) async {
    try {
      final dio = DioUtil.token(baseUrl: _baseUrl);
      final res = await dio.get("/channel/$pageNo/$pageSize");

      if (res.statusCode == 200 && res.data != null) {
        return AgoraChannelInfo.fromJson(res.data);
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
