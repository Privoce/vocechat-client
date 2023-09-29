import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/group/group_create_request.dart';
import 'package:vocechat_client/api/models/group/group_create_response.dart';
import 'package:vocechat_client/api/models/group/group_update_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class GroupApi {
  late final String _baseUrl;

  GroupApi({String? serverUrl}) {
    final url = serverUrl ?? App.app.chatServerM.fullUrl;
    _baseUrl = "$url/api/group";
  }

  Future<Response<int>> createBfe033(GroupCreateRequest req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    final res = await dio.post("", data: req);

    var newRes = Response<int>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as int;
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response<GroupCreateResponse>> createAft033(
      GroupCreateRequest req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    final res = await dio.post("", data: req);

    var newRes = Response<GroupCreateResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = GroupCreateResponse.fromJson(res.data);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response> addMembers(int gid, List<int> adds) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return await dio.post("/$gid/members/add", data: json.encode(adds));
  }

  Future<Response> removeMembers(int gid, List<int> removes) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return await dio.post("/$gid/members/remove", data: json.encode(removes));
  }

  Future<Response> delete(int gid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    return dio.delete("/$gid");
  }

  Future<Response> pin(int gid, int mid, bool toPin) async {
    // if pinned == 0, it has not pinned before. Thus needs to be pinned.
    String pinAction = toPin ? 'pin' : 'unpin';
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "application/json";

    return await dio.post("/$gid/$pinAction", data: json.encode({'mid': mid}));
  }

  Future<Response<int>> sendTextMsg(
      int gid, String msg, Map<String, dynamic>? properties) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeText;
    // dio.options.receiveTimeout = Duration(milliseconds: 10000);
    dio.options.receiveTimeout = Duration(milliseconds: 10000);

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

    print("headers: ${dio.options.headers}");

    final res = await dio.post("/$gid/send", data: msg);

    var newRes = Response<int>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as int;
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response<int>> sendMarkdownMsg(int gid, String msg, String cid) async {
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

    final res = await dio.post("/$gid/send", data: msg);

    var newRes = Response<int>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as int;
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response<int>> sendArchiveMsg(
      int gid, String cid, String archiveId) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    Map<String, dynamic> properties = {'cid': cid};

    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeArchive;

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

    final res = await dio.post("/$gid/send", data: archiveId);

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

  Future<Response<int>> sendFileMsg(int gid, String cid, String path,
      {int? width, int? height}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    Map<String, dynamic> refererHeader = {
      'referer': App.app.chatServerM.fullUrl
    };
    if (App.app.chatServerM.url == "dev.voce.chat") {
      refererHeader = {'referer': "https://privoce.voce.chat"};
    }
    dio.options.headers.addAll(refererHeader);

    Map<String, dynamic> properties = {'cid': cid};
    if (width != null && height != null) {
      properties.addAll({'width': width, 'height': height});
    }
    dio.options.headers["x-properties"] =
        base64.encode(utf8.encode(json.encode(properties)));
    dio.options.headers["content-type"] = typeFile;

    final data = {'path': path};

    final res = await dio.post("/$gid/send", data: json.encode(data));

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
    int gid,
    String cid,
    String path,
  ) async {
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
    dio.options.headers["content-type"] = typeAudio;

    final data = {'path': path};

    final res = await dio.post("/$gid/send", data: json.encode(data));

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

  Future<Response> getInvitePrivateMagicLink(int gid,
      {int? expiredIn = 172800, int? maxTimes = 1}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    String url = "/create_invite_private_magic_link";

    List<String> paramList = [];

    paramList.add("gid=$gid");

    if (expiredIn != null) {
      paramList.add("expired_in=$expiredIn");
    }

    if (maxTimes != null) {
      paramList.add("max_times=$maxTimes");
    }

    if (paramList.isNotEmpty) {
      final str = paramList.join("&");
      url += "?$str";
    }

    var uri = Uri.parse(_baseUrl + url);
    dio.options.headers["Authority"] = "${uri.authority}:${uri.port}";
    dio.options.headers["Host"] = uri.host;

    return dio.get(url);
  }

  Future<Response<String>> uploadGroupAvatar(
      int gid, Uint8List avatarBytes) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    dio.options.headers["content-type"] = "image/png";

    return dio.post(
      "/$gid/avatar",
      data: Stream.fromIterable(avatarBytes.map((e) => [e])),
      options: Options(
        headers: {
          Headers.contentLengthHeader: avatarBytes.length, // set content-length
        },
      ),
    );
  }

  Future<Response> updateGroup(int gid, GroupUpdateRequest req) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.put("/$gid", data: req);
  }

  Future<Response> leaveGroup(int gid) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return dio.get("/$gid/leave");
  }

  Future<Response> getHistory(int gid, int? beforeMid,
      {int limit = 20, bool enableRetry = false}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl, enableRetry: enableRetry);

    String url = "/$gid/history?limit=$limit";

    if (beforeMid != null) {
      url += "&before=$beforeMid";
    }

    return dio.get(url);
  }

  Future<Response> getRegMagicLink(
      {int? gid, int? expiredIn = 172800, int? maxTimes = 1}) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    String url = "/create_reg_magic_link";

    List<String> paramList = [];

    if (gid != null) {
      paramList.add("gid=$gid");
    }

    if (expiredIn != null) {
      paramList.add("expired_in=$expiredIn");
    }

    if (maxTimes != null) {
      paramList.add("max_times=$maxTimes");
    }

    if (paramList.isNotEmpty) {
      final str = paramList.join("&");
      url += "?$str";
    }

    var uri = Uri.parse(_baseUrl + url);
    dio.options.headers["Authority"] = "${uri.authority}:${uri.port}";
    dio.options.headers["Host"] = uri.host;

    return dio.get(url);
  }

  Future<Response<String>> changeType(int gid, bool isPublic) async {
    final dio = DioUtil.token(baseUrl: _baseUrl);

    return dio.post(
      "/$gid/change_type",
      data: jsonEncode({"is_public": isPublic}),
    );
  }
}
