import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/token_api.dart';
import 'package:vocechat_client/api/models/token/login_response.dart';
import 'package:vocechat_client/api/models/token/token_login_request.dart';
import 'package:vocechat_client/api/models/token/token_renew_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/services/sse.dart';

class AuthService {
  AuthService({required this.chatServerM}) {
    adminSystemApi = AdminSystemApi(chatServerM.fullUrl);
  }

  // final UserDbM userDb;
  final ChatServerM chatServerM;
  late final AdminSystemApi adminSystemApi;

  static const int renewBase = 15;
  int renewFactor = 1;

  Timer? _timer;
  static const threshold = 60; // Refresh tokens if remaining time < 60.

  int _expiredIn = 0;

  void setTimer(int expiredIn) {
    if (_timer != null) {
      _timer!.cancel();
    }
    // Check if token needs refreshing every 10 seconds.
    const interval = 10;

    _expiredIn = expiredIn;

    _timer = Timer.periodic(Duration(seconds: interval), (_timer) async {
      // App.logger.config("Current token expires in $_expiredIn seconds");

      if (_expiredIn < 0) {
        // token expires.
        _timer.cancel();
      }
      if (_expiredIn <= threshold && _expiredIn >= threshold - 5) {
        renewAuthToken();
      }
      _expiredIn -= interval;
    });
  }

  void disableTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  Future<bool> renewAuthToken() async {
    App.app.statusService.fireTokenLoading(LoadingStatus.loading);
    try {
      if (App.app.userDb == null) {
        App.app.statusService.fireTokenLoading(LoadingStatus.disconnected);
        return false;
      }
      final req = TokenRenewRequest(
          App.app.userDb!.token, App.app.userDb!.refreshToken);

      final _tokenApi = TokenApi(chatServerM.fullUrl);
      final res = await _tokenApi.tokenRenewPost(req);

      if (res.statusCode == 200 && res.data != null) {
        renewFactor = 1;

        App.logger.config("Token Refreshed.");
        final data = res.data!;
        final token = data.token;
        final refreshToken = data.refreshToken;
        final expiredIn = data.expiredIn;

        setTimer(expiredIn);
        await _renewAuthDataInUserDb(token, refreshToken, expiredIn);

        return true;
      }
      App.logger.severe("Renew Token Failed, Status code: ${res.statusCode}");
    } catch (e) {
      App.logger.severe(e);
    }

    _expiredIn = threshold + renewBase * renewFactor;
    renewFactor += 1;
    if (renewFactor > 4) {
      renewFactor = 4;
    }
    App.app.statusService.fireTokenLoading(LoadingStatus.disconnected);
    return false;
  }

  Future<void> _renewAuthDataInUserDb(
      String token, String refreshToken, int expiredIn) async {
    final status = await StatusMDao.dao.getStatus();
    if (status == null) {
      App.logger.severe("Empty UserDbId in Status Db");
      return;
    }

    final newUserDbM = await UserDbMDao.dao
        .updateAuth(status.userDbId, token, refreshToken, expiredIn);
    App.app.userDb = newUserDbM;
    App.app.statusService.fireTokenLoading(LoadingStatus.success);
  }

  ///
  Future<bool> login(TokenLoginRequest req) async {
    final _tokenApi = TokenApi(chatServerM.fullUrl);
    final res = await _tokenApi.tokenLoginPost(req);

    String content = "";

    if (res.statusCode != 200) {
      switch (res.statusCode) {
        case 401:
          content = "Invalid account or password.";
          break;
        case 403:
          content = "Login method is not supported.";
          break;
        case 404:
          content = "User does not exist.";
          break;
        case 409:
          content = "Email collision.";
          break;
        case 423:
          content = "User has been frozed.";
          break;
        default:
          content = "An error occured during login.";
      }

      await showAppAlert(
          context: navigatorKey.currentContext!,
          title: "Login Error",
          content: content,
          actions: [
            AppAlertDialogAction(
              text: "OK",
              action: () {
                Navigator.pop(navigatorKey.currentContext!);
              },
            )
          ]);

      return false;
    }

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data!;
      await initServices(data);

      return true;
    }

    return false;
  }

  Future<bool> initServices(LoginResponse res) async {
    final String serverId = res.serverId;
    final token = res.token;
    final refreshToken = res.refreshToken;
    final expiredIn = res.expiredIn;
    final userInfo = res.user;
    final userInfoJson = json.encode(userInfo.toJson());
    final dbName = "${serverId}_${userInfo.uid}";

    final chatServerId = App.app.chatServerM.id;

    final old = await UserDbMDao.dao.first(
        where: '${UserDbM.F_chatServerId} = ? AND ${UserDbM.F_uid} = ?',
        whereArgs: [dbName, userInfo.uid]);

    late UserDbM newUserDb;
    if (old == null) {
      UserDbM m = UserDbM.item(
          userInfo.uid,
          userInfoJson,
          dbName,
          chatServerId,
          DateTime.now().millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
          token,
          refreshToken,
          expiredIn,
          1,
          -1,
          -1,
          "");
      newUserDb = await UserDbMDao.dao.addOrUpdate(m);
    } else {
      UserDbM m = UserDbM.item(
          userInfo.uid,
          userInfoJson,
          dbName,
          chatServerId,
          old.createdAt,
          DateTime.now().millisecondsSinceEpoch,
          token,
          refreshToken,
          expiredIn,
          1,
          old.usersVersion,
          old.maxMid,
          "");
      newUserDb = await UserDbMDao.dao.addOrUpdate(m);
    }

    App.app.userDb = newUserDb;
    StatusM statusM = StatusM.item(newUserDb.id);
    await StatusMDao.dao.replace(statusM);
    setTimer(expiredIn);

    await initCurrentDb(dbName);

    App.app.chatService = ChatService();

    return true;
  }

  Future<bool> logout() async {
    try {
      Sse.sse.close();

      if (App.app.userDb == null) {
        if (_timer != null) {
          _timer!.cancel();
        }
        _timer = null;
        return false;
      }
      final curUserDb = App.app.userDb!;
      App.app.userDb = await UserDbMDao.dao.updateWhenLogout(curUserDb.id);
      App.app.chatService = ChatService();

      if (_timer != null) {
        _timer!.cancel();
      }

      await closeUserDb();

      final _tokenApi = TokenApi(chatServerM.fullUrl);
      final res = await _tokenApi.getLogout();
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> selfDelete() async {
    try {
      await logout();

      final path =
          "${(await getApplicationDocumentsDirectory()).path}/${App.app.userDb!.dbName}";
      print(path);

      await Directory(path).delete(recursive: true);

      App.app.userDb = null;

      return true;
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
  }
}
