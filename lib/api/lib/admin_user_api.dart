import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';

class AdminUserApi {
  late final String _baseUrl;

  AdminUserApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/admin/user";
  }

  Future<Response> deleteUser(int uid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.delete("$uid");
  }

  Future<Response<bool>> getSmtpEnableStatus() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    return dio.get("/enabled");
  }
}
