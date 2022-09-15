import 'package:flutter/material.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/services/sse.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';

/// A place for app infos and services.
class App {
  static final App app = App._internal();

  static final logger = SimpleLogger();

  // bool initialized;

  // Initilized in UI/Auth/login_page.dart

  // Initialized in service - db.dart

  // initialized in login page.
  late StatusService statusService;
  AuthService? authService;

  // initialized after a successful login action.
  late ChatService chatService;

  // initialized in login page
  UserDbM? userDb;

  // will be updated in ChatService. No need to handle manually.
  Map<int, bool> onlineStatusMap = {};

  ChatServerM chatServerM = ChatServerM();

  bool isSelf(int? uid) {
    return uid == userDb?.uid;
  }

  factory App() {
    return app;
  }

  Future<void> changeUser(UserDbM userDbM) async {
    // Switch database
    await closeUserDb();
    await initCurrentDb(userDbM.dbName);

    final userDbId = userDbM.id;

    // Update StatusM (only has one status at a time)
    final statusM = StatusM.item(userDbId);
    await StatusMDao.dao.removeAll();
    await StatusMDao.dao.addOrReplace(statusM);

    chatServerM =
        (await ChatServerDao.dao.getServerById(userDbM.chatServerId))!;

    // Update Services
    authService?.dispose();
    chatService.dispose();
    statusService.dispose();

    userDb = userDbM;
    statusService = StatusService();
    authService = AuthService(chatServerM: chatServerM);
    chatService = ChatService();

    eventBus.fire(UserChangeEvent(userDbM));

    // connect
    if (authService != null) {
      if (await authService!.renewAuthToken()) {
        chatService.initSse();
      } else {}
    }
  }

  Future<void> changeUserAfterLogOut() async {
    final loggedInUserDbList =
        (await UserDbMDao.dao.getList())?.where((e) => e.loggedIn == 1) ?? [];

    if (loggedInUserDbList.isEmpty) {
      if (navigatorKey.currentContext != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ServerPage(),
            ),
            (route) => false);
        return;
      }
    } else {
      final next = loggedInUserDbList.first;
      await changeUser(next);
    }
  }

  App._internal();
}

class AuthData {
  final String token;
  final String refreshToken;
  final int expiredIn;
  // final UserInfo user;

  AuthData(
      {required this.token,
      required this.refreshToken,
      required this.expiredIn});
}
