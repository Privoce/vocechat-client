import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:simple_logger/simple_logger.dart';

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

  // final Map<int, UserInfoM> userInfoMMap = {};
  final Map<int, bool> onlineStatusMap = {};

  ChatServerM chatServerM = ChatServerM();

  bool isSelf(int? uid) {
    return uid == userDb?.uid;
  }

  factory App() {
    return app;
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
