import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/admin/system/sys_org_info.dart';
import 'package:vocechat_client/app.dart';

class AdminSystemApi {
  late final String _baseUrl;

  AdminSystemApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/admin/system";
  }

  Future<Response> setOrgInfo({String? name, String? description}) async {
    Map<String, dynamic> req = {};

    if (name != null) {
      req.addAll({"name": name});
    }

    if (description != null) {
      req.addAll({"description": description});
    }

    final dio = DioUtil.token(baseUrl: _baseUrl);

    return dio.post("/organization", data: jsonEncode(req));
  }

  Future<Response<AdminSystemOrgInfo>> getOrgInfo() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    final res = await dio.get("/organization");

    var newRes = Response<AdminSystemOrgInfo>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = AdminSystemOrgInfo.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response> uploadOrgLogo(Uint8List avatarBytes) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "image/png";
    dio.options.validateStatus = (status) {
      return [200, 413].contains(status);
    };

    return dio.post(
      "/orgnization/logo",
      // data: jsonEncode(avatarBytes)
      data: Stream.fromIterable(avatarBytes.map((e) => [e])),
      options: Options(
        headers: {
          Headers.contentLengthHeader: avatarBytes.length, // set content-length
        },
      ),
    );
  }

  Future<Response<bool>> getInitialized() async {
    final dio = DioUtil(baseUrl: _baseUrl);

    return dio.get("/initialized");
  }
}
