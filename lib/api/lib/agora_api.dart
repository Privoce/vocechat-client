import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import '../models/token/token_agora_response.dart';
import 'dio_retry/options.dart';
import 'dio_retry/retry_interceptor.dart';

class AgoraApi {
  late final String _baseUrl;

  AgoraApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/group";
  }

  Future<Response<TokenAgoraResponse>> generatesAgoraToken(int gid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    final res = await dio.get(
      "/$gid/agora_token",
    );
    var newRes = Response<TokenAgoraResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = TokenAgoraResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  // Future<Response<UserInfo>> getUserByUid(int uid) async {
  //   final dio = Dio();
  //   dio.interceptors.add(RetryInterceptor(
  //       dio: dio, options: RetryOptions(retryInterval: Duration(seconds: 2))));
  //   dio.options.baseUrl = _baseUrl;
  //   dio.options.connectTimeout = 5000; //5s
  //   dio.options.receiveTimeout = 10000;
  //
  //   final res = await dio.get("/$uid");
  //
  //   var newRes = Response<UserInfo>(
  //       headers: res.headers,
  //       requestOptions: res.requestOptions,
  //       isRedirect: res.isRedirect,
  //       statusCode: res.statusCode,
  //       statusMessage: res.statusMessage,
  //       redirects: res.redirects,
  //       extra: res.extra);
  //
  //   if (res.statusCode == 200 && res.data != null) {
  //     final data = UserInfo.fromJson(res.data!);
  //     newRes.data = data;
  //   }
  //   return newRes;
  // }
}
