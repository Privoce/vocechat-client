import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';
import 'package:vocechat_client/services/sse.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/chats_page.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/ui/auth/login_page.dart';
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
      }

      App.app.chatServerM =
          (await ChatServerDao.dao.getServerById(userDb.chatServerId))!;

      App.app.statusService = StatusService();
      App.app.authService = AuthService(chatServerM: App.app.chatServerM);

      App.app.chatService = ChatService();

      // Get / update org info.
      try {
        final orgInfoRes =
            await App.app.authService!.adminSystemApi.getOrgInfo();
        if (orgInfoRes.statusCode == 200 && orgInfoRes.data != null) {
          final orgInfo = orgInfoRes.data!;
          App.app.chatServerM.properties = ChatServerProperties(
              serverName: orgInfo.name, description: orgInfo.description ?? "");

          final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
          final logoRes = await resourceApi.getOrgLogo();
          if (logoRes.statusCode == 200 && logoRes.data != null) {
            App.app.chatServerM.logo = logoRes.data!;
          }

          App.app.chatServerM.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await ChatServerDao.dao.addOrUpdate(App.app.chatServerM);
        }
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  runApp(VoceChatApp(defaultHome: _defaultHome));
}

// ignore: must_be_immutable
class VoceChatApp extends StatefulWidget {
  VoceChatApp({required this.defaultHome, Key? key}) : super(key: key);

  late Widget defaultHome;

  @override
  State<VoceChatApp> createState() => _VoceChatAppState();
}

class _VoceChatAppState extends State<VoceChatApp> with WidgetsBindingObserver {
  late Widget _defaultHome;
  late bool shouldRefresh;
  late bool _isInitLoad;
  late bool _isLoading;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _defaultHome = widget.defaultHome;
    shouldRefresh = false;

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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
        supportedLocales: const [
          Locale('en', ''), // English, no country code
        ],
        home: _defaultHome,
      ),
    );
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
    print("Connectivity: $result");
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.none) {
      await Future.delayed(Duration(seconds: 2));
      await _connect();
    }
    // if (result == ConnectivityResult.none) {
    //   App.app.authService!.disableTimer();
    // }
  }

  Future<void> _connect() async {
    final status = await StatusMDao.dao.getStatus();
    if (status == null) return;
    final userDb = await UserDbMDao.dao.getUserDbById(status.userDbId);
    if (userDb == null) {
      return;
    }

    if (App.app.authService != null) {
      if (await App.app.authService!.renewAuthToken()) {
        if (Sse.sse.isClosed()) {
          App.app.chatService.initSse();
        }
      } else {
        Sse.sse.close();
      }
    }

    _isLoading = false;
  }
}
