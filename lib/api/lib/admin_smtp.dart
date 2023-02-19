import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/admin/smtp/smtp.dart';
import 'package:vocechat_client/app.dart';

class AdminSmtpApi {
  late final String _baseUrl;

  AdminSmtpApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/smtp";
  }

  Future<Response> postSmtpConfigs(AdminSmtp req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return await dio.post("/config",
        data: json.encode(req).replaceAll(r"\\n", r"\n"));
  }

  Future<Response<AdminSmtp>> getSmtpConfigs() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    final res = await dio.get("/config");

    var newRes = Response<AdminSmtp>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = AdminSmtp.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response<bool>> getSmtpEnableStatus() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    return dio.get("/enabled");
  }
}
