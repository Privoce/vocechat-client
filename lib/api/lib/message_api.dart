import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class MessageApi {
  late final String _baseUrl;

  MessageApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/message";
  }

  Future<Response> edit(int mid, String msgStr) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["Content-Type"] = typeText;
    final res = await dio.put("/$mid/edit",
        options: Options(responseType: ResponseType.bytes), data: msgStr);

    var newRes = Response<Uint8List>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = Uint8List.fromList(res.data!);
    }
    return newRes;
  }

  Future<Response> react(int mid, String action) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    final res = await dio.put("/$mid/like",
        options: Options(responseType: ResponseType.bytes),
        data: {"action": action});

    var newRes = Response<Uint8List>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = Uint8List.fromList(res.data!);
    }
    return newRes;
  }

  Future<Response> delete(int mid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.delete("/$mid",
        options: Options(responseType: ResponseType.bytes));
  }

  Future<Response<int>> reply(
      int mid, String msgStr, Map<String, dynamic>? properties) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    dio.options.headers["X-Properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["Content-Type"] = typeText;
    final res = await dio.post("/$mid/reply", data: msgStr);

    var newRes = Response<int>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data! as int;
      newRes.data = data;
    }
    return newRes;
  }
}
