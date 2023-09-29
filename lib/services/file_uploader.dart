import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:vocechat_client/api/models/resource/file_upload_response.dart';
import 'package:vocechat_client/app.dart';

class FileUploader {
  late final Dio _dio;
  Uint8List fileBytes;
  final String fileId;
  final Function(double)? onUploadProgress;
  late int _maxChunkSize, _fileSize;

  FileUploader(
      {required this.fileBytes, required this.fileId, this.onUploadProgress}) {
    _dio = Dio();
    // _dio.interceptors.add(RetryInterceptor(
    //     dio: _dio, options: RetryOptions(retryInterval: Duration(seconds: 2))));

    _dio.options.baseUrl = "${App.app.chatServerM.fullUrl}/api/resource";
    _dio.options.connectTimeout = Duration(milliseconds: 5000); //5s

    // _dio.options.receiveTimeout = 10000;
    _dio.options.headers["accept"] = "application/json";
    _dio.options.headers["content-type"] = "multipart/form-data";
    _dio.options.headers["X-API-Key"] = App.app.userDb!.token;
    _fileSize = fileBytes.length;
    _maxChunkSize = min(_fileSize, 1024 * 1024);
  }

  Future<Response<FileUploadResponse>?> upload(String type) async {
    Response res;
    final mainType = type.split("/").first;
    final subType = type.split("/").last;
    for (int i = 0; i < _chunksCount; i++) {
      final start = _getChunkStart(i);
      final end = _getChunkEnd(i);
      var chunkData = MultipartFile.fromBytes(_getChunk(start, end),
          contentType: MediaType(mainType, subType));

      final formData = FormData.fromMap({
        'file_id': fileId,
        'chunk_data': chunkData,
        'chunk_is_last': i == (_chunksCount - 1)
      });
      final extraFormDataSize = formData.length - chunkData.length;

      res = await _dio.post(
        "/file/upload",
        data: formData,
        onSendProgress: (current, total) =>
            _updateProgress(i, current - extraFormDataSize, total),
      );

      if (i == (_chunksCount - 1)) {
        var finalRes = Response<FileUploadResponse>(
            headers: res.headers,
            requestOptions: res.requestOptions,
            isRedirect: res.isRedirect,
            statusCode: res.statusCode,
            statusMessage: res.statusMessage,
            redirects: res.redirects,
            extra: res.extra);
        if (res.statusCode == 200 && res.data != null) {
          finalRes.data = FileUploadResponse.fromJson(res.data!);
          return finalRes;
        }
      }
    }
    return null;
  }

  Uint8List _getChunk(int start, int end) {
    return fileBytes.sublist(start, end);
  }

  // Updating total upload progress
  _updateProgress(int chunkIndex, int chunkCurrent, int chunkTotal) {
    if (chunkTotal == -1) {
      return;
    }
    int totalUploadedSize = (chunkIndex * _maxChunkSize) + chunkCurrent;
    totalUploadedSize = totalUploadedSize < 0 ? 0 : totalUploadedSize;
    double decimalProgress = totalUploadedSize / _fileSize;
    double totalUploadProgress = decimalProgress * 100;
    onUploadProgress?.call(decimalProgress);
    // eventBus.fire(MsgProgressPercentEvent(totalUploadProgress,));
    App.logger.info(
        "$totalUploadedSize / $_fileSize | $totalUploadProgress % | chunktotal $chunkTotal");
  }

  // Returning start byte offset of current chunk
  int _getChunkStart(int chunkIndex) => chunkIndex * _maxChunkSize;

  // Returning end byte offset of current chunk
  int _getChunkEnd(int chunkIndex) =>
      min((chunkIndex + 1) * _maxChunkSize, _fileSize);

  // Returning a header map object containing Content-Range
  // https://tools.ietf.org/html/rfc7233#section-2
  Map<String, dynamic> _getHeaders(int start, int end) =>
      {'Content-Range': 'bytes $start-${end - 1}/$_fileSize'};

  // Returning chunks count based on file size and maximum chunk size
  int get _chunksCount => (_fileSize / _maxChunkSize).ceil();
}
