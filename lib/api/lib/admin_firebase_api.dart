import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/admin/fcm/fcm.dart';
import 'package:vocechat_client/app.dart';

class AdminFirebaseApi {
  late final String _baseUrl;

  AdminFirebaseApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/admin/fcm";
  }

  Future<Response> postFcmConfigs(AdminFcm req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return await dio.post("/config",
        data: json.encode(req).replaceAll(r"\\n", r"\n"));
  }

  Future<Response<AdminFcm>> getFcmConfigs() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    final res = await dio.get("/config");

    var newRes = Response<AdminFcm>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = AdminFcm.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }
}
