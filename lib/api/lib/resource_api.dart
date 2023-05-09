import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/api/models/resource/file_prepare_request.dart';
import 'package:vocechat_client/api/models/resource/file_upload_response.dart';
import 'package:vocechat_client/app.dart';

import 'package:vocechat_client/api/models/resource/open_graphic_parse_response.dart';

class ResourceApi {
  late final String _baseUrl;

  ResourceApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/resource";
  }

  Future<Response<Uint8List>> getImage(String imageId) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    final res = await dio.get<List<int>>("/image?id=$imageId",
        options: Options(responseType: ResponseType.bytes));

    var newRes = Response<Uint8List>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);
    res.extra;

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = Uint8List.fromList(res.data!);
    }
    return newRes;
  }

  Future<Response<Uint8List>> getUserAvatar(int uid,
      {bool enableServerRetry = true}) async {
    final dio = DioUtil(baseUrl: _baseUrl, enableRetry: enableServerRetry);
    final res = await dio.get<List<int>>("/avatar?uid=$uid",
        options: Options(responseType: ResponseType.bytes));

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

  Future<Response<Uint8List>?> getGroupAvatar(int gid,
      {bool enableServerRetry = true}) async {
    final dio = DioUtil(baseUrl: _baseUrl, enableRetry: enableServerRetry);

    // Do not treat 404 as an exception to avoid Dio package flaw: can't catch
    // 404 exception for this request.
    dio.options.validateStatus = (status) {
      return [200, 404].contains(status);
    };

    try {
      final res = await dio.get("/group_avatar?gid=$gid",
          options: Options(responseType: ResponseType.bytes));

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

        return newRes;
      }
    } catch (e) {
      App.logger.warning(e);
    }
    return null;
  }

  Future<Response<Uint8List>> getOrgLogo() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    final res = await dio.get<List<int>>("/organization/logo",
        options: Options(responseType: ResponseType.bytes));

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

  Future<Response<String>> prepareFile(FilePrepareRequest req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    final res = await dio.post("/file/prepare", data: req.toJson());

    var newRes = Response<String>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = res.data! as String;
    }
    return newRes;
  }

  Future<Response<FileUploadResponse>> uploadFile(
      String fileId, Uint8List chunkData, bool chunkIsLast, String path) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "multipart/form-data";

    int maxChunkSize = 1024 * 1024;

    File file = File(path);
    int fileSize = file.lengthSync();
    maxChunkSize = min(fileSize, maxChunkSize);
    // ignore: unused_local_variable
    int chunksCount = (fileSize / maxChunkSize).ceil();

    var formData = FormData.fromMap({
      'file_id': fileId,
      'chunk_data': chunkData,
      'chunk_is_last': chunkIsLast
    });
    final res = await dio.post("/file/upload", data: formData);

    var newRes = Response<FileUploadResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = res.data! as FileUploadResponse;
    }
    return newRes;
  }

  Future<Response<Uint8List>> getFile(
      String filePath, bool thumb, bool download,
      [Function(int, int)? onReceiveProgress]) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final res = await dio.get(
        "/file?file_path=$filePath&thumbnail=$thumb&download=$download",
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress);

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

  Future<Response<Uint8List>> download(String url) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final res =
        await dio.get("", options: Options(responseType: ResponseType.bytes));

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

  Future<Response<String>> archive(List<int> midList) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    final res =
        await dio.post("/archive", data: json.encode({"mid_list": midList}));

    var newRes = Response<String>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = res.data! as String;
    }
    return newRes;
  }

  Future<Response<Archive>> getArchive(String archiveId) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.validateStatus = (status) {
      return [200, 404].contains(status);
    };

    final res = await dio.get("/archive?file_path=$archiveId");

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

  Future<Response<Uint8List>> getArchiveAttachment(
      String filePath, int attachmentId, bool enableDownload,
      [Function(int, int)? onProgress]) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final res = await dio.get(
        "/archive/attachment?file_path=$filePath&attachment_id=$attachmentId&download=$enableDownload",
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

  Future<Response<OpenGraphicParseResponse>> getOpenGraphicParse(
      String url) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";
    final res = await dio.get(
      "/open_graphic_parse?url=$url",
    );

    var newRes = Response<OpenGraphicParseResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = OpenGraphicParseResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }
}
