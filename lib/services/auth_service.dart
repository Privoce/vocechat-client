import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/token_api.dart';
import 'package:vocechat_client/api/models/token/credential.dart';
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
import 'package:vocechat_client/services/status_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthService {
  static final AuthService _service = AuthService._internal();
  AuthService._internal();

  factory AuthService({required ChatServerM chatServerM}) {
    _service.chatServerM = chatServerM;
    _service.adminSystemApi = AdminSystemApi(chatServerM.fullUrl);

    App.app.chatServerM = chatServerM;

    return _service;
  }

  late ChatServerM chatServerM;
  late AdminSystemApi adminSystemApi;

  // static const int renewBase = 15;
  // int renewFactor = 1;

  List<int> retryList = const [2, 2, 4, 8, 16, 32, 64];
  int retryIndex = 0;

  Timer? _fcmTimer;
  int _fcmExpiresIn = 0;

  Timer? _timer;
  static const threshold = 60; // Refresh tokens if remaining time < 60.

  int _expiredIn = 0;

  void _setTimer(int expiredIn) {
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
        if (await renewAuthToken()) {
          if (Sse.sse.isClosed()) {
            Sse.sse.connect();
          }
        }
      }
      _expiredIn -= interval;
    });
  }

  void dispose() {
    disableAuthTimer();
  }

  void disableAuthTimer() {
    _timer!.cancel();
  }

  void disableFcmTImer() {
    _fcmTimer?.cancel();
  }

  Future<bool> renewAuthToken() async {
    App.app.statusService.fireTokenLoading(TokenStatus.connecting);
    try {
      if (App.app.userDb == null) {
        App.app.statusService.fireTokenLoading(TokenStatus.disconnected);
        return false;
      }
      final req = TokenRenewRequest(
          App.app.userDb!.token, App.app.userDb!.refreshToken);

      final _tokenApi = TokenApi(chatServerM.fullUrl);
      final res = await _tokenApi.tokenRenewPost(req);

      if (res.statusCode == 200 && res.data != null) {
        _resetRetryInterval();

        App.logger.config("Token Refreshed.");
        final data = res.data!;
        final token = data.token;
        final refreshToken = data.refreshToken;
        final expiredIn = data.expiredIn;

        _setTimer(expiredIn);
        await _renewAuthDataInUserDb(token, refreshToken, expiredIn);

        return true;
      } else {
        if (res.statusCode == 401 || res.statusCode == 403) {
          App.logger
              .severe("Renew Token Failed, Status code: ${res.statusCode}");
          _increaseRetryInterval();
          App.app.statusService.fireTokenLoading(TokenStatus.unauthorized);
          return false;
        }
      }
      App.logger.severe("Renew Token Failed, Status code: ${res.statusCode}");
    } catch (e) {
      App.logger.severe(e);
    }

    _increaseRetryInterval();
    App.app.statusService.fireTokenLoading(TokenStatus.disconnected);
    return false;
  }

  /// Increase retry interval index by 1,
  /// If index reaches [retryList.length], index won't change, otherwise increase
  /// by 1.
  /// updated [_expiredIn] value include basic [threshold], which is 60 sec by
  /// default.
  void _increaseRetryInterval() {
    if (retryIndex >= 0 && retryIndex < retryList.length - 1) {
      retryIndex += 1;
    }
    _expiredIn = threshold + retryList[retryIndex];
  }

  /// Resets retry interval index to 0, which 2 seconds.
  void _resetRetryInterval() {
    retryIndex = 0;
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
    App.app.statusService.fireTokenLoading(TokenStatus.successful);
  }

  Future<bool> tryReLogin() async {
    final userdb = App.app.userDb;
    if (userdb == null) return false;

    final dbName = App.app.userDb?.dbName;
    if (dbName == null || dbName.isEmpty) return false;

    final storage = FlutterSecureStorage();
    final pswd = await storage.read(key: dbName);

    if (pswd == null || pswd.isEmpty) return false;

    return login(userdb.userInfo.email!, pswd, true, true);
  }

  Future<String> _getFirebaseDeviceToken() async {
    String deviceToken = "";

    try {
      final cancellableOperation = CancelableOperation.fromFuture(
        FirebaseMessaging.instance.getToken(),
        onCancel: () {
          deviceToken = "";
          return;
        },
      ).then((token) {
        deviceToken = token ?? "";
      });

      Timer(Duration(seconds: 3), (() {
        App.logger.info("FCM timeout (3s), handled by VoceChat");
        cancellableOperation.cancel();
      }));
      // deviceToken = await FirebaseMessaging.instance.getToken() ?? "";
      return deviceToken;
    } catch (e) {
      App.logger.warning(e);
      deviceToken = "";
    }
    return deviceToken;
  }

  Future<TokenLoginRequest> _preparePswdLoginRequest(
      String email, String pswd) async {
    final deviceToken = await _getFirebaseDeviceToken();

    String device;

    if (Platform.isIOS) {
      device = "iOS";
    } else if (Platform.isAndroid) {
      device = "Android";
    } else {
      device = "Others";
    }

    final credential = Credential(email, pswd, "password");

    final req = TokenLoginRequest(
        device: device, credential: credential, deviceToken: deviceToken);
    return req;
  }

  Future<bool> login(String email, String pswd, bool rememberPswd,
      [bool isReLogin = false]) async {
    String errorContent = "";
    try {
      final _tokenApi = TokenApi(chatServerM.fullUrl);

      final req = await _preparePswdLoginRequest(email, pswd);
      final res = await _tokenApi.tokenLoginPost(req);

      if (res.statusCode != 200) {
        switch (res.statusCode) {
          case 401:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent401;
            break;
          case 403:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent403;
            break;
          case 404:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent404;
            break;
          case 409:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent409;
            break;
          case 423:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent423;
            break;
          case 451:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent451;
            break;
          default:
            App.logger.severe("Error: ${res.statusCode} ${res.statusMessage}");
            errorContent =
                "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther} ${res.statusCode} ${res.statusMessage}";
        }
      } else if (res.statusCode == 200 && res.data != null) {
        final data = res.data!;
        if (await initServices(data, rememberPswd,
            rememberPswd ? req.credential.password : null)) {
          App.app.chatService.initSse();
          return true;
        } else {
          errorContent =
              "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther}(initialization).";
        }
      } else {
        errorContent =
            "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther}  ${res.statusCode} ${res.statusMessage}";
      }
    } catch (e) {
      App.logger.severe(e);
      errorContent = e.toString();
    }

    await showAppAlert(
        context: navigatorKey.currentContext!,
        title: AppLocalizations.of(navigatorKey.currentContext!)!.loginError,
        content: errorContent,
        actions: [
          AppAlertDialogAction(
            text: AppLocalizations.of(navigatorKey.currentContext!)!.ok,
            action: () {
              Navigator.pop(navigatorKey.currentContext!);
            },
          )
        ]);

    return false;
  }

  Future<bool> initServices(LoginResponse res, bool rememberMe,
      [String? password]) async {
    try {
      final String serverId = res.serverId;
      final token = res.token;
      final refreshToken = res.refreshToken;
      final expiredIn = res.expiredIn;
      final userInfo = res.user;
      final userInfoJson = json.encode(userInfo.toJson());
      final dbName = "${serverId}_${userInfo.uid}";

      // Save password to secure storage.
      final storage = FlutterSecureStorage();
      if (rememberMe) {
        if (password != null && password.isNotEmpty) {
          await storage.write(key: dbName, value: password);
        }
      } else {
        await storage.delete(key: dbName);
      }

      final avatarBytes = userInfo.avatarUpdatedAt == 0
          ? Uint8List(0)
          : (await ResourceApi(App.app.chatServerM.fullUrl)
                      .getUserAvatar(userInfo.uid))
                  .data ??
              Uint8List(0);

      final chatServerId = App.app.chatServerM.id;

      final old = await UserDbMDao.dao.first(
          where: '${UserDbM.F_chatServerId} = ? AND ${UserDbM.F_uid} = ?',
          whereArgs: [chatServerId, userInfo.uid]);

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
            avatarBytes,
            "",
            0);
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
            avatarBytes,
            "",
            old.maxMid);
        newUserDb = await UserDbMDao.dao.addOrUpdate(m);
      }

      App.app.userDb = newUserDb;
      StatusM statusM = StatusM.item(newUserDb.id);
      await StatusMDao.dao.replace(statusM);
      _setTimer(expiredIn);

      await initCurrentDb(dbName);

      App.app.chatService = ChatService();
      App.app.statusService = StatusService();

      return true;
    } catch (e) {
      App.logger.severe(e);

      final context = navigatorKey.currentState?.context;
      if (context != null) {
        final error = e.toString();
        showAppAlert(
            context: context,
            title:
                AppLocalizations.of(navigatorKey.currentContext!)!.loginError,
            content:
                "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther} (initialization).",
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(navigatorKey.currentContext!)!
                      .loginErrorCopy,
                  action: () {
                    Clipboard.setData(ClipboardData(text: error));
                    Navigator.of(context).pop();
                  }),
              AppAlertDialogAction(
                  text: AppLocalizations.of(navigatorKey.currentContext!)!.ok,
                  action: () {
                    Navigator.of(context).pop();
                  })
            ]);
      }
    }

    return false;
  }

  Future<bool> logout({bool markLogout = true, bool isKicked = false}) async {
    try {
      Sse.sse.close();

      final curUserDb = App.app.userDb!;

      if (markLogout) {
        App.app.userDb = await UserDbMDao.dao.updateWhenLogout(curUserDb.id);
      }

      dispose();
      App.app.chatService.dispose();
      App.app.statusService.dispose();

      if (!isKicked) {
        await closeUserDb();
      }

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

      // Delete all data of this user.
      final path =
          "${(await getApplicationDocumentsDirectory()).path}/${App.app.userDb!.dbName}";
      await Directory(path).delete(recursive: true);

      // Delete user history data.
      await UserDbMDao.dao.remove(App.app.userDb!.id);
      final storage = FlutterSecureStorage();
      await storage.delete(key: App.app.userDb!.dbName);

      App.app.userDb = null;

      return true;
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
  }
}
