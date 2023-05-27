import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';

class AdminUserApi {
  late final String _baseUrl;

  AdminUserApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/admin/user";
  }

  Future<Response> deleteUser(int uid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.delete("/$uid");
  }

  Future<Response<bool>> getSmtpEnableStatus() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    return dio.get("/enabled");
  }
}
