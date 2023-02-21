import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/services/sse/sse.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_page.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/contact/contacts_page.dart';
import 'package:vocechat_client/ui/settings/settings_page.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disables https self-signed certificates for easier dev. To be solved.
  // HttpOverrides.global = DevHttpOverrides();

  await _setUpFirebaseNotification();

  App.logger.setLevel(Level.CONFIG, includeCallerInfo: true);

  await initDb();

  Widget _defaultHome = ChatsMainPage();

  // Handling login status
  final status = await StatusMDao.dao.getStatus();
  if (status == null) {
    _defaultHome = ServerPage();
  } else {
    final userDb = await UserDbMDao.dao.getUserDbById(status.userDbId);
    if (userDb == null) {
      _defaultHome = ServerPage();
    } else {
      App.app.userDb = userDb;
      await initCurrentDb(App.app.userDb!.dbName);

      if (userDb.loggedIn != 1) {
        Sse.sse.close();
        _defaultHome = ServerPage();
      } else {
        final chatServerM =
            await ChatServerDao.dao.getServerById(userDb.chatServerId);
        if (chatServerM == null) {
          _defaultHome = ServerPage();
        } else {
          App.app.chatServerM = chatServerM;

          App.app.statusService = StatusService();
          App.app.authService = AuthService(chatServerM: App.app.chatServerM);

          App.app.chatService = ChatService();
        }
      }
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) {
    runApp(VoceChatApp(defaultHome: _defaultHome));
  });
}

Future<void> _setUpFirebaseNotification() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    if (kDebugMode) {
      print('User granted permission');
    }
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    if (kDebugMode) {
      print('User granted provisional permission');
    }
  } else {
    if (kDebugMode) {
      print('User declined or has not accepted permission');
    }
  }
}

// ignore: must_be_immutable
class VoceChatApp extends StatefulWidget {
  VoceChatApp({required this.defaultHome, Key? key}) : super(key: key);

  late Widget defaultHome;

  static _VoceChatAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_VoceChatAppState>();

  @override
  State<VoceChatApp> createState() => _VoceChatAppState();
}

class _VoceChatAppState extends State<VoceChatApp> with WidgetsBindingObserver {
  late Widget _defaultHome;
  late bool shouldRefresh;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Locale? _locale;

  /// When network changes, such as from wi-fi to data, a relay is set to avoid
  /// [_connect()] function to be called repeatly.
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _defaultHome = widget.defaultHome;
    shouldRefresh = false;

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _initLocale();

    _handleIncomingUniLink();
    _handleInitUniLink();

    _handleInitialNotification();
    _setupForegroundNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('app resumed');
        onResume();
        setState(() {
          shouldRefresh = false;
        });
        break;
      case AppLifecycleState.paused:
        print('app paused');
        setState(() {
          shouldRefresh = true;
        });

        break;
      case AppLifecycleState.inactive:
        print('app inactive');
        // setState(() {
        //   shouldRefresh = false;
        // });
        break;
      case AppLifecycleState.detached:
      default:
        print('app detached');
        setState(() {
          shouldRefresh = true;
        });
        break;
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'VoceChat',
        routes: {
          // Auth
          // ServerPage.route: (context) => ServerPage(),
          // LoginPage.route: (context) => LoginPage(),
          // Chats
          ChatsMainPage.route: (context) => ChatsMainPage(),
          ChatsPage.route: (context) => ChatsPage(),
          // Contacts
          ContactsPage.route: (context) => ContactsPage(),
          ContactDetailPage.route: (context) => ContactDetailPage(),
          // Settings
          SettingPage.route: (context) => SettingPage(),
        },
        theme: ThemeData(
            // canvasColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: AppColors.grey200,
            fontFamily: 'Inter',
            primarySwatch: Colors.blue,
            dividerTheme: DividerThemeData(thickness: 0.5, space: 1),
            textTheme: TextTheme(
                // headline6:
                // Chats tile title, contacts
                // titleSmall: ,
                // titleMedium:
                //     TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                // All AppBar titles
                titleLarge:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        // theme: ThemeData.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: _locale,
        supportedLocales: const [
          Locale('en', 'US'), // English, no country code
          Locale('zh', ''),
        ],
        home: _defaultHome,
      ),
    );
  }

  Future<void> _handleInitialNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // notification from background, but not terminated state.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  /// Currently do nothing to foreground notifications,
  /// but keep this function for potential future use.
  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("FCM received: ${message.data}");

      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification?.body}');
        }
      }
    });
  }

  Future<void> _initLocale() async {
    final userDbM = await UserDbMDao.dao.getUserDbById(App.app.userDb!.id);
    final userLanguageTag = userDbM?.userInfo.language;

    if (userLanguageTag != null && userLanguageTag.isNotEmpty) {
      final split = userLanguageTag.split("-");
      String languageTag = "", scriptTag = "", regionTag = "";
      try {
        languageTag = split[0];
        scriptTag = split[1];
        regionTag = split[2];
      } catch (e) {
        App.logger.warning(e);
      }
      final locale = Locale(languageTag, regionTag);

      setLocale(locale);
    }
  }

  void _handleMessage(RemoteMessage message) async {
    print(message.data);
  }

  Future<InvitationLinkData?> _parseLink(Uri uri) async {
    final param = uri.queryParameters["magic_link"];
    if (param == null || param.isEmpty) return null;

    try {
      final invLinkUri = Uri.parse(param);

      final magicToken = invLinkUri.queryParameters["magic_token"];
      String serverUrl = invLinkUri.scheme +
          '://' +
          invLinkUri.host +
          ":" +
          invLinkUri.port.toString();

      if (serverUrl == "https://privoce.voce.chat" ||
          serverUrl == "https://privoce.voce.chat:443") {
        serverUrl = "https://dev.voce.chat";
      }

      if (magicToken != null && magicToken.isNotEmpty) {
        if (await _validateMagicToken(serverUrl, magicToken)) {
          return InvitationLinkData(
              serverUrl: serverUrl, magicToken: magicToken);
        } else {
          final context = navigatorKey.currentContext;
          if (context == null) return null;
          _showInvalidLinkWarning(context);
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }

    return null;
  }

  void _showInvalidLinkWarning(BuildContext context) {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.invalidInvitationLinkWarning,
        content:
            AppLocalizations.of(context)!.invalidInvitationLinkWarningContent,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.ok,
              action: (() => Navigator.of(context).pop()))
        ]);
  }

  void _handleIncomingUniLink() async {
    uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;

      final linkData = await _parseLink(uri);
      if (linkData == null) return;

      _handleUniLink(linkData);
    });
  }

  Future<bool> _validateMagicToken(String url, String magicToken) async {
    try {
      final res = await UserApi(serverUrl: url).checkMagicToken(magicToken);
      return (res.statusCode == 200 && res.data == true);
    } catch (e) {
      App.logger.severe(e);
    }

    return false;
  }

  void _handleInitUniLink() async {
    final initialUri = await getInitialUri();
    if (initialUri == null) return;

    final linkData = await _parseLink(initialUri);
    if (linkData == null) return;

    _handleUniLink(linkData);
  }

  void _handleUniLink(InvitationLinkData data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    try {
      final chatServer = await ChatServerHelper(context: context)
          .prepareChatServerM(data.serverUrl, showAlert: false);
      if (chatServer == null) return;

      final route = PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PasswordRegisterPage(
                chatServer: chatServer, magicToken: data.magicToken),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.fastOutSlowIn;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );

      Navigator.push(context, route);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void onResume() async {
    try {
      if (App.app.authService == null) {
        return;
      }

      // if pre is inactive, do nothing.
      if (!shouldRefresh) {
        return;
      }

      await _connect();
    } catch (e) {
      App.logger.severe(e);
      if (App.app.authService == null) {
        return;
      }

      App.app.authService!.logout().then((value) {
        if (value) {
          navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => ServerPage(),
              ),
              (route) => false);
        } else {
          navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => ServerPage(),
              ),
              (route) => false);
        }
      });
    }
  }

  void onPaused() {}

  void onInactive() {
    // Sse.sse.close();
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    App.logger.info("Connectivity: $result");
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.none) {
      await _connect();
    }
  }

  Future<void> _connect() async {
    if (_isConnecting) return;

    _isConnecting = true;

    final status = await StatusMDao.dao.getStatus();
    if (status != null) {
      final userDb = await UserDbMDao.dao.getUserDbById(status.userDbId);
      if (userDb != null) {
        if (App.app.authService != null) {
          if (await SharedFuncs.renewAuthToken()) {
            App.app.chatService.initSse();
          } else {
            Sse.sse.close();
          }
        }
      }
    }

    _isConnecting = false;
    return;
  }
}

class InvitationLinkData {
  String serverUrl;
  String magicToken;

  InvitationLinkData({required this.serverUrl, required this.magicToken});
}
