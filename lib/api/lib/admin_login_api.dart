import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/admin/login/login_config.dart';
import 'package:vocechat_client/app.dart';

class AdminLoginApi {
  late final String _baseUrl;

  AdminLoginApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/login";
  }

  Future<Response> postConfig(AdminLoginConfig info) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return await dio.post("/config", data: info);
  }

  Future<Response<AdminLoginConfig>> getConfig(
      {bool enableRetry = false}) async {
    final dio = DioUtil(baseUrl: _baseUrl, enableRetry: enableRetry);
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
