import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/admin/agora/agora_config.dart';
import 'package:vocechat_client/api/models/admin/agora/agora_token_response.dart';
import 'package:vocechat_client/api/models/admin/smtp/smtp.dart';
import 'package:vocechat_client/app.dart';

class AdminAgoraApi {
  late final String _baseUrl;

  AdminAgoraApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/agora";
  }

  Future<Response<AgoraTokenResponse>> generateAgoraToken(int uid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    final req = {"uid": uid};

    final res = await dio.post("/token", data: json.encode(req));

    var newRes = Response<AgoraTokenResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = AgoraTokenResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response> setAgoraConfig(AgoraConfig config) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.post("/config", data: json.encode(config.toJson()));
  }

  Future<Response<AgoraConfig>> getAgoraConfig() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    final res = await dio.get("/config");

    var newRes = Response<AgoraConfig>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = AgoraConfig.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }
}
