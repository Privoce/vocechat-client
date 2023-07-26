import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/event_bus_objects/push_to_chat_event.dart';
import 'package:vocechat_client/firebase_options.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/helpers/shared_preference_helper.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/services/sse/sse.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_page.dart';
import 'package:vocechat_client/ui/contact/contacts_page.dart';
import 'package:vocechat_client/ui/settings/settings_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _setUpFirebaseNotification();

  App.logger.setLevel(Level.CONFIG, includeCallerInfo: true);

  await initDb();

  Widget defaultHome = ChatsMainPage();

  // await SharedFuncs.readCustomConfigs();

  // Handling login status
  final status = await StatusMDao.dao.getStatus();
  if (status == null) {
    defaultHome = await SharedFuncs.getDefaultHomePage();
  } else {
    final userDb = await UserDbMDao.dao.getUserDbById(status.userDbId);
    if (userDb == null) {
      defaultHome = await SharedFuncs.getDefaultHomePage();
    } else {
      App.app.userDb = userDb;
      await initCurrentDb(App.app.userDb!.dbName);

      if (userDb.loggedIn != 1) {
        Sse.sse.close();
        defaultHome = await SharedFuncs.getDefaultHomePage();
      } else {
        final chatServerM =
            await ChatServerDao.dao.getServerById(userDb.chatServerId);
        if (chatServerM == null) {
          defaultHome = await SharedFuncs.getDefaultHomePage();
        } else {
          App.app.chatServerM = chatServerM;

          App.app.statusService = StatusService();
          App.app.authService = AuthService(chatServerM: App.app.chatServerM);
          App.app.chatService = VoceChatService();
        }
      }
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) {
    runApp(VoceChatApp(defaultHome: defaultHome));
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

  // ignore: library_private_types_in_public_api
  static _VoceChatAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_VoceChatAppState>();

  @override
  State<VoceChatApp> createState() => _VoceChatAppState();
}

class _VoceChatAppState extends State<VoceChatApp> with WidgetsBindingObserver {
  late Widget _defaultHome;

  /// Whether the app should fetch new tokens from server.
  ///
  /// When app lifecycle goes through [paused] and [detached], it is set to true.
  /// When app lifecycle goes through [resumed], it is set back to false.
  bool shouldRefresh = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Locale? _locale;

  /// When network changes, such as from wi-fi to data, a relay is set to avoid
  /// [_connect()] function to be called repeatly.
  bool _isConnecting = false;

  bool _firstTimeRefreshSinceAppOpens = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _defaultHome = widget.defaultHome;

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
        App.logger.info('App lifecycle: app resumed');

        onResume();

        shouldRefresh = false;

        break;
      case AppLifecycleState.paused:
        App.logger.info('App lifecycle: app paused');

        shouldRefresh = true;

        break;
      case AppLifecycleState.inactive:
        App.logger.info('App lifecycle: app inactive');
        break;
      case AppLifecycleState.detached:
      default:
        App.logger.info('App lifecycle: app detached');

        shouldRefresh = true;

        break;
    }
  }

  void _initLocale() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final savedLocale = sharedPreferences.getString('locale');
    if (savedLocale != null) {
      setState(() {
        _locale = Locale(savedLocale);
      });
    } else {
      setState(() {
        _locale = window.locale;
      });
    }
  }

  void setUILocale(Locale newLocale) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _locale = newLocale;
    });
    await sharedPreferences.setString('locale', newLocale.languageCode);
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
          // ContactDetailPage.route: (context) => ContactDetailPage(),
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
          Locale('en', ''), // English, no country code
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
      _handleRemoteNotificationMessage(initialMessage);
    }

    // notification from background, but not terminated state.
    FirebaseMessaging.onMessageOpenedApp
        .listen(_handleRemoteNotificationMessage);
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

  void _handleRemoteNotificationMessage(RemoteMessage message) async {
    final notificationServerId = message.data['vocechat_server_id'];

    // [currentServerId] might be empty.
    // TODO: change to more formal way of storaging server id.
    // final currentServerId = App.app.chatServerM.serverId;

    final currentServerId = App.app.userDb!.dbName.split("_").first;

    if (currentServerId.isEmpty) return;

    final uidStr = message.data['vocechat_to_uid'] as String?;
    final gidStr = message.data['vocechat_to_gid'] as String?;
    final uid = uidStr == null ? null : int.tryParse(uidStr);
    final gid = gidStr == null ? null : int.tryParse(gidStr);

    if (notificationServerId != currentServerId) {
      final userDbs = await UserDbMDao.dao.getList();
      if (userDbs == null) return;
      for (final userDb in userDbs) {
        if (userDb.dbName.split("_").first == notificationServerId) {
          await App.app.changeUser(userDb).then((_) {
            // TODO: change to: waiting for sse ready.
            Future.delayed(Duration(milliseconds: 1000)).then((value) {
              eventBus.fire(PushToChatEvent(uid: uid, gid: gid));
            });
          });
          return;
        }
      }
    } else {
      eventBus.fire(PushToChatEvent(uid: uid, gid: gid));
    }
  }

  void switchServerOnNotification(String serverId, int? uid, int? gid) async {}

  void _handleIncomingUniLink() async {
    uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      _parseLink(uri);
    });
  }

  void _handleInitUniLink() async {
    final initialUri = await getInitialUri();
    if (initialUri == null) return;
    _parseLink(initialUri);
  }

  void _parseLink(Uri uri) async {
    App.logger.info("UniLink/DeepLink: $uri");
    await SharedFuncs.parseUniLink(uri);
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

      App.app.authService!.logout().then((value) async {
        final defaultHomePage = await SharedFuncs.getDefaultHomePage();
        if (value) {
          navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => defaultHomePage,
              ),
              (route) => false);
        } else {
          navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => defaultHomePage,
              ),
              (route) => false);
        }
      });
    }
  }

  void onPaused() {}

  void onInactive() {}

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
          if (await SharedFuncs.renewAuthToken(
              forceRefresh: _firstTimeRefreshSinceAppOpens)) {
            _firstTimeRefreshSinceAppOpens = false;
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

class UniLinkData {
  String link;
  UniLinkType type;

  UniLinkData({required this.link, required this.type});
}

enum UniLinkType { login, register }
