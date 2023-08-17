import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/api/models/token/login_response.dart';
import 'package:vocechat_client/api/models/user/register_request.dart';
import 'package:vocechat_client/api/models/user/send_reg_magic_token_request.dart';
import 'package:vocechat_client/api/models/user/send_reg_magic_token_response.dart';
import 'package:vocechat_client/api/models/user/user_contact.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/contacts.dart';
import 'package:vocechat_client/ui/contact/contacts_add_segmented_control.dart';

class UserApi {
  late final String _baseUrl;

  UserApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/user";
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

    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: false);
    dio.options.validateStatus = (status) {
      return status! == 200 || status == 409;
    };

    return dio.put("", data: req);
  }

  Future<Response> get() async {
    final dio = DioUtil(baseUrl: _baseUrl);
    return await dio.get("");
  }

  Future<Response<int>> sendTextMsg(int uid, String content, String cid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode({'cid': cid})));
    dio.options.headers["content-type"] = typeText;

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

    final res = await dio.post("/$uid/send", data: content);

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

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

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

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

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

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

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

  Future<Response<int>> sendAudioMsg(
    int dmUid,
    String cid,
    String path,
  ) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    Map<String, dynamic> properties = {'cid': cid};

    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeAudio;

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

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
    final dio = DioUtil.token(baseUrl: _baseUrl);
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

  Future<Response> mute(String req, {bool enableRetry = false}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: enableRetry);
    dio.options.headers["content-type"] = "application/json";

    return dio.post("/mute", data: req);
  }

  Future<Response<bool>> checkEmail(String email) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return dio.get("/check_email?email=$email");
  }

  Future<Response<bool>> checkMagicToken(String magicToken,
      {bool enableRetry = false}) async {
    final dio = DioUtil(baseUrl: _baseUrl, enableRetry: enableRetry);
    dio.options.headers["content-type"] = "application/json";
    dio.options.connectTimeout = 2000;

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

    newRes.data = res.statusCode == 200 && res.data == true;
    return newRes;
  }

  Future<Response<LoginResponse>> register(RegisterRequest req) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.validateStatus = (status) {
      return [200, 409, 412].contains(status);
    };

    final res = await dio.post("/register", data: req.toJson());

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
    dio.options.headers["content-type"] = "application/json";

    Map reqMap = {};
    if (uid != null) {
      reqMap = {
        "users": [
          {"uid": uid, "expires_in": expiresIn}
        ]
      };
    } else if (gid != null) {
      reqMap = {
        "groups": [
          {"gid": gid, "expires_in": expiresIn}
        ]
      };
    }

    return dio.post("/burn-after-reading", data: json.encode(reqMap));
  }

  Future<Response> delete() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.delete("/delete");
  }

  Future<Response<SendRegMagicTokenResponse>> sendRegMagicLink(
      SendRegMagicTokenRequest req) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    final res = await dio.post("/send_reg_magic_link", data: req);

    var newRes = Response<SendRegMagicTokenResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = SendRegMagicTokenResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response<List<UserContact>>> getUserContacts() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    final res = await dio.get("/contacts");

    var newRes = Response<List<UserContact>>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final List<UserContact> list = [];

      for (var item in res.data!) {
        final data = UserContact.fromJson(item);
        list.add(data);
      }
      newRes.data = list;
    }
    return newRes;
  }

  Future<Response> updateContactStatus(
      int uid, ContactUpdateAction status) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: false);
    dio.options.headers["content-type"] = "application/json";

    return dio.post("/update_contact_status",
        data: {"action": status.name, "target_uid": uid});
  }

  Future<Response<UserInfo?>> search(
      ContactSearchType type, String keyword) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: false);
    dio.options.headers["content-type"] = "application/json";

    final res = await dio
        .post("/search", data: {"search_type": type.name, "keyword": keyword});

    var newRes = Response<UserInfo?>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final userInfo = UserInfo.fromJson(res.data);
      newRes.data = userInfo;
    }
    return newRes;
  }

  Future<Response> pinChat(
      {int? uid, int? gid, bool enableRetry = false}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: enableRetry);
    dio.options.headers["content-type"] = "application/json";

    Map reqMap = {};
    if (uid != null) {
      reqMap = {"uid": uid};
    } else if (gid != null) {
      reqMap = {"gid": gid};
    }

    reqMap = {"target": reqMap};

    return dio.post("/pin_chat", data: json.encode(reqMap));
  }

  Future<Response> unpinChat(
      {int? uid, int? gid, bool enableRetry = false}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: enableRetry);
    dio.options.headers["content-type"] = "application/json";

    Map reqMap = {};
    if (uid != null) {
      reqMap = {"uid": uid};
    } else if (gid != null) {
      reqMap = {"gid": gid};
    }

    reqMap = {"target": reqMap};

    return dio.post("/unpin_chat", data: json.encode(reqMap));
  }

  Future<Response<GroupInfo>> joinPrivateChannel(String magicToken) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    final res = await dio.post("/join_private",
        data: json.encode({"magic_token": magicToken}));

    var newRes = Response<GroupInfo>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      newRes.data = GroupInfo.fromJson(res.data!);
    }
    return newRes;
  }

  Future<Response> changePassword(String oldPswd, String newPswd) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: false);
    dio.options.headers["content-type"] = "application/json";

    return dio.post("/change_password",
        data: json.encode({"old_password": oldPswd, "new_password": newPswd}));
  }
}
