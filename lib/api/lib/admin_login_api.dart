import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/admin/fcm/fcm.dart';
import 'package:vocechat_client/api/models/admin/login/login_config.dart';

class AdminLoginApi {
  late final String _baseUrl;

  AdminLoginApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/admin/login";
  }

  Future<Response> postConfig(AdminLoginConfig info) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return await dio.post("/config", data: info);
  }

  Future<Response<AdminLoginConfig>> getConfig() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    final res = await dio.get("/config");

    var newRes = Response<AdminLoginConfig>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = AdminLoginConfig.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }
}
