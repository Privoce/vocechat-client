import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/token/login_response.dart';
import 'package:vocechat_client/api/models/user/register_request.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class UserApi {
  late final String _baseUrl;

  UserApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/user";
  }

  Future<Response> updateUserInfo(
      {String? name, int? gender, String? language, String? password}) async {
    Map<String, dynamic> req = {};

    if (name != null) {
      req.addAll({"name": name});
    }

    if (gender != null) {
      req.addAll({"gender": gender});
    }

    if (language != null) {
      req.addAll({"language": language});
    }

    if (password != null) {
      req.addAll({"password": password});
    }

    final dio = DioUtil.token(baseUrl: _baseUrl, withRetry: false);
    dio.options.validateStatus = (status) {
      return status! == 200 || status == 409;
    };

    return dio.put("", data: req);
  }

  Future<Response> get() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    return await dio.get("");
  }

  Future<Response<int>> sendTextMsg(int dmUid, String msg, String cid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode({'cid': cid})));
    dio.options.headers["content-type"] = typeText;
    final res = await dio.post("/$dmUid/send", data: msg);

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

  Future<Response<int>> sendMarkdownMsg(
      int dmUid, String msg, String cid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode({'cid': cid})));
    dio.options.headers["content-type"] = typeText;
    final res = await dio.post("/$dmUid/send", data: msg);

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

  Future<Response<int>> sendArchiveMsg(
      int dmUid, String cid, String archiveId) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    Map<String, dynamic> properties = {'cid': cid};

    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeArchive;

    final res = await dio.post("/$dmUid/send", data: archiveId);

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

  Future<Response<int>> sendFileMsg(int dmUid, String cid, String path,
      {int? width, int? height}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    Map<String, dynamic> properties = {'cid': cid};
    if (width != null && height != null) {
      properties.addAll({'width': width, 'height': height});
    }
    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeFile;

    final data = {'path': path};

    final res = await dio.post("/$dmUid/send", data: json.encode(data));

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

  Future<Response<UserInfo>> getUserByUid(int uid) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    final res = await dio.get("/$uid");

    var newRes = Response<UserInfo>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = UserInfo.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response> updateReadIndex(String req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return dio.post("/read-index", data: req);
  }

  Future<Response> uploadAvatar(Uint8List avatarBytes) async {
    final dio = Dio();
    dio.interceptors.add(RetryInterceptor(
        dio: dio, options: RetryOptions(retryInterval: Duration(seconds: 2))));
    dio.options.baseUrl = _baseUrl;
    dio.options.connectTimeout = 5000; //5s
    dio.options.receiveTimeout = 10000;
    dio.options.headers["X-API-Key"] = App.app.userDb!.token;
    dio.options.headers["content-type"] = "image/png";
    dio.options.validateStatus = (status) {
      return [200, 413].contains(status);
    };

    return dio.post(
      "/avatar",
      // data: jsonEncode(avatarBytes)
      data: Stream.fromIterable(avatarBytes.map((e) => [e])),
      options: Options(
        headers: {
          Headers.contentLengthHeader: avatarBytes.length, // set content-length
        },
      ),
    );
  }

  Future<Response<String>> sendLoginMagicLink(String email) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    String url = "/send_login_magic_link?email=$email";

    return dio.post<String>(url);
  }

  Future<Response> mute(String req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return dio.post("/mute", data: req);
  }

  Future<Response<bool>> checkEmail(String email) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return dio.get("/check_email?email=$email");
  }

  Future<Response<bool>> checkMagicToken(String magicToken) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    final res = await dio.post("/check_magic_token",
        data: json.encode({"magic_token": magicToken}));

    var newRes = Response<bool>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    newRes.data = res.statusCode == 200 && res.data != null;
    return newRes;
  }

  Future<Response<LoginResponse>> register(RegisterRequest req) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.validateStatus = (status) {
      return [200, 409, 412].contains(status);
    };

    final res = await dio.post("/register", data: req);

    var newRes = Response<LoginResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = LoginResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response> postBurnAfterReadingSetting(
      {int? uid, int? gid, required int expiresIn}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    Map reqMap = {};
    if (uid != null) {
      reqMap = {
        "users": [
          {"uid": uid, "expiresIn": expiresIn}
        ]
      };
    } else if (gid != null) {
      reqMap = {
        "groups": [
          {"gid": gid, "expiresIn": expiresIn}
        ]
      };
    }

    return await dio.post("/burn-after-reading", data: jsonEncode(reqMap));
  }

  Future<Response> delete() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.delete("/delete");
  }
}
