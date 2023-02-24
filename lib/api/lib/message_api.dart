import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class MessageApi {
  late final String _baseUrl;

  MessageApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/message";
  }

  Future<Response> edit(int mid, String msgStr) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = typeText;
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
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: false);
    return dio.delete("/$mid",
        options: Options(responseType: ResponseType.bytes));
  }

  Future<Response<int>> reply(
      int mid, String msgStr, Map<String, dynamic>? properties) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeText;
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
