import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/api/models/saved/saved_response.dart';
import 'package:vocechat_client/app.dart';

class SavedApi {
  late final String _baseUrl;

  SavedApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/favorite";
  }

  Future<Response<SavedResponse>> createSaved(List<int> midList) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    // dio.options.validateStatus = (status) {
    //   return [200, 429].contains(status);
    // };

    final res = await dio.post("", data: json.encode({"mid_list": midList}));

    var newRes = Response<SavedResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = SavedResponse.fromJson(res.data!);
    }
    return newRes;
  }

  Future<Response<List<dynamic>>> listSaved() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return dio.get("");
  }

  Future<Response> deleteSaved(String archiveId) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    return dio.delete("/$archiveId");
  }

  Future<Response<Archive>> getSaved(String archiveId) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    final res = await dio.get("/$archiveId");

    var newRes = Response<Archive>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      Archive archive = Archive.fromJson(res.data);
      newRes.data = archive;
    }
    return newRes;
  }

  Future<Response<Uint8List>> getSavedAttachment(
      int uid, String filePath, int attachmentId, bool enableDownload,
      [Function(int, int)? onProgress]) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final res = await dio.get(
        "/attachment/$uid/$filePath/$attachmentId?&download=$enableDownload",
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress);

    var newRes = Response<Uint8List>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = newRes.data = Uint8List.fromList(res.data!);
    }
    return newRes;
  }
}
