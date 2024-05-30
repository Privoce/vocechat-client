import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocechat_client/api/lib/admin_login_api.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/token_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/token/token_renew_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/event_bus_objects/private_channel_link_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/helpers/shared_preference_helper.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/invitation_link_paste_page.dart';
import 'package:vocechat_client/ui/auth/login_page.dart';
import 'package:vocechat_client/ui/auth/register/register_password_page.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';

import 'models/local_kits.dart';

class SharedFuncs {
  // local variables.
  static Completer<bool> _tokenCompleter = Completer();
  static bool isRenewingToken = false;

  /// Clear all local data
  static Future<void> clearLocalData() async {
    if (navigatorKey.currentState?.context == null) return;

    final context = navigatorKey.currentState!.context;

    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.clearLocalData,
        content: AppLocalizations.of(context)!.clearLocalDataContent,
        primaryAction: AppAlertDialogAction(
            text: AppLocalizations.of(context)!.ok,
            isDangerAction: true,
            action: () async {
              try {
                await closeAllDb();
              } catch (e) {
                App.logger.severe(e);
              }

              try {
                await removeDb();
              } catch (e) {
                App.logger.severe(e);
              }

              exit(0);
            }),
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.pop(context, 'Cancel'))
        ]);
  }

  /// Generate chatId in file path when doing file storage
  static String? getChatId({int? uid, int? gid}) {
    if (uid != null && uid != -1) {
      return "U$uid";
    } else if (gid != null && gid != -1) {
      return "G$gid";
    }
    return null;
  }

  /// Return default home page, in case [EnvConstants.voceBaseUrl] is set.
  static Future<Widget> getDefaultHomePage() async {
    if (hasPreSetServerUrl()) {
      return LoginPage(
          baseUrl: App.app.customConfig!.configs.serverUrl,
          disableBackButton: true);
    }
    return ServerPage();
  }

  /// Translate bytes to readable file size string.
  static String getFileSizeString(int bytes) {
    try {
      const suffixes = ["b", "kb", "mb", "gb", "tb"];
      const int base = 1000;
      var i = (log(bytes) / log(base)).floor();
      return ((bytes / pow(base, i)).toStringAsFixed(1)) +
          suffixes[i].toUpperCase();
    } catch (e) {
      return "0 kb";
    }
  }

  /// Get first, or first two, if exists, initials of a name string, used for
  /// user avatars.
  static String getInitials(String input, {int limit = 4}) {
    return input.isNotEmpty
        ? input
            .trim()
            .split(RegExp(
                '[\u0009\u000a\u000b\u000c\u000d\u0020\u0085\u00a0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u200c\u200d\u2028\u2029\u202f\u205f\u2060\u3000\ufeff]+'))
            .map((s) => s.characters.toList()[0])
            .take(limit)
            .join()
            .toUpperCase()
        : '';
  }

  static Future<String> getAppVersion({bool withBuildNum = false}) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    if (withBuildNum) {
      String buildNumber = packageInfo.buildNumber;
      return "$version($buildNumber)";
    } else {
      return version;
    }
  }

  static Future<void> handleInvitationLink(Uri uri) async {
    final invitationLink = uri.queryParameters["i"];

    if (invitationLink == null || invitationLink.isEmpty) return;

    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          InvitationLinkPastePage(initialLink: invitationLink),
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

    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(route);
  }

  static Future<void> handleIncomingLink(Uri uri) async {}

  static Future<void> handleQrCode(Uri uri) async {}

  static Future<void> handleServerLink(Uri uri) async {
    final serverUrl = uri.queryParameters["s"];

    final context = navigatorKey.currentContext;
    if (serverUrl == null || serverUrl.isEmpty || context == null) return;
    try {
      await ChatServerHelper()
          .prepareChatServerM(serverUrl, showAlert: false)
          .then((chatServer) {
        if (chatServer != null) {
          final route = PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LoginPage(baseUrl: serverUrl),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
        }
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  static bool hasPreSetServerUrl() {
    return App.app.customConfig?.hasPreSetServerUrl ?? false;
  }

  static bool isSelf(int? uid) {
    return uid == App.app.userDb?.uid;
  }

  static Future<bool> appLaunchUrl(Uri uri) async {
    if (Platform.isIOS) {
      return launchUrl(uri);
    } else {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void onQrCodeDetected(String link) async {
    final uri = Uri.parse(link);

    if (uri.scheme != "http" && uri.scheme != "https") {
      return;
    }

    final modifiedLink = link.replaceFirst("/#", "");
    final modifiedUri = Uri.parse(modifiedLink).replace(fragment: '');

    // Handle invitation link
    if (modifiedUri.queryParameters.containsKey("magic_token")) {
      // considerd as a potential invitation link.
      await _onInvitationLinkDetected(modifiedUri);
    } else {
      if (!await SharedFuncs.appLaunchUrl(uri)) {
        throw Exception('Could not launch $uri');
      }
    }
  }

  static Future<void> _onInvitationLinkDetected(Uri uri) async {
    // _isBusy.value = true;
    await SharedFuncs.parseInvitationUri(uri).then((res) {
      App.logger.info("Invitation link preparation status: ${res.status}");
      switch (res.status) {
        case InvitationLinkPreparationStatus.successful:
          final route = PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PasswordRegisterPage(
                    chatServer: res.chatServerM!,
                    magicToken: res.magicToken!,
                    invitationLink: res.uri),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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

          final context = navigatorKey.currentContext;
          if (context != null) {
            Navigator.of(context).push(route);
          }

          break;
        case InvitationLinkPreparationStatus.networkError:
          // _isBusy.value = false;
          // _showNetworkErrorWarning(context);
          break;
        case InvitationLinkPreparationStatus.invalid:
          // _isBusy.value = false;
          // _showInvalidInvitationLinkWarning(context);
          break;
        default:
      }
    }).onError((error, stackTrace) {
      // _isBusy.value = false;
      App.logger.severe(error);
    });

    // _isBusy.value = false;
  }

  static Future<void> parseUniLink(Uri uri) async {
    if (!uri.queryParameters.containsKey("magic_link")) {
      return;
    }

    final context = navigatorKey.currentContext;

    try {
      final magicLink = uri.queryParameters["magic_link"]!;
      final modifiedLink = magicLink.replaceFirst("/#", "");
      final modifiedUri = Uri.parse(modifiedLink).replace(fragment: '');

      await SharedFuncs.parseInvitationUri(modifiedUri).then((res) {
        App.logger.info("Invitation link preparation status: ${res.status}");
        switch (res.status) {
          case InvitationLinkPreparationStatus.successful:
            final route = PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PasswordRegisterPage(
                      chatServer: res.chatServerM!,
                      magicToken: res.magicToken!,
                      invitationLink: res.uri),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.fastOutSlowIn;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );

            if (context != null) {
              Navigator.of(context).push(route);
            }

            break;
          case InvitationLinkPreparationStatus.networkError:
            // _isBusy.value = false;
            if (context != null) {
              _showNetworkErrorWarning(context);
            }
            break;
          case InvitationLinkPreparationStatus.invalid:
            // _isBusy.value = false;
            if (context != null) {
              _showInvalidLinkWarning(context);
            }
            break;
          default:
        }
      }).onError((error, stackTrace) {
        // _isBusy.value = false;
        App.logger.severe(error);
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  /// Input a modified invitation link (without hash#).
  static Future<QrScanResult> parseInvitationUri(Uri uri) async {
    try {
      String host = uri.host;
      if (host == "privoce.voce.chat") {
        host = "dev.voce.chat";
      }

      final apiPath =
          "${uri.scheme}://$host${uri.hasPort ? ":${uri.port}" : ""}";
      final userApi = UserApi(serverUrl: apiPath);
      final magicToken = uri.queryParameters["magic_token"] as String;

      final res = await userApi.checkMagicToken(magicToken);
      if (res.statusCode == 200 && res.data == true) {
        final chatServerM =
            await ChatServerHelper().prepareChatServerM(apiPath);
        if (chatServerM?.fullUrl == App.app.chatServerM.fullUrl &&
            App.app.userDb?.loggedIn != 0) {
          // Current chat server is the same as the invitation link,
          // and is logged in.
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments[0] == "invite_private") {
            eventBus.fire(PrivateChannelInvitationLinkEvent(uri));
          } else {
            return QrScanResult(
                chatServerM: chatServerM,
                magicToken: magicToken,
                uri: uri,
                status: InvitationLinkPreparationStatus.successful);
          }
        } else if (chatServerM != null) {
          return QrScanResult(
              chatServerM: chatServerM,
              magicToken: magicToken,
              uri: uri,
              status: InvitationLinkPreparationStatus.successful);
        }
      } else if (res.statusCode == 599) {
        App.logger.severe("Network Error");

        return QrScanResult(
            status: InvitationLinkPreparationStatus.networkError);
      } else {
        App.logger.warning("Link not valid. link: $uri");

        return QrScanResult(status: InvitationLinkPreparationStatus.invalid);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return QrScanResult(status: InvitationLinkPreparationStatus.invalid);
  }

  /// Parse mention info in text and markdowns.
  /// It changes uid to username when mention format occurs.
  static Future<String> parseMention(String snippet) async {
    String text;

    Map<int, String> nameMap = {};
    final regex = RegExp(r'\s@[0-9]+\s');

    for (final each in regex.allMatches(snippet)) {
      try {
        final uid =
            int.parse(snippet.substring(each.start, each.end).substring(2));
        final user = await UserInfoDao().getUserByUid(uid);
        final username = user?.userInfo.name ?? uid.toString();
        nameMap.addAll({uid: username});
      } catch (e) {
        App.logger.severe(e);
      }
    }

    text = snippet.splitMapJoin(regex, onMatch: (Match match) {
      final uidStr = match[0]?.substring(2);
      if (uidStr != null && uidStr.isNotEmpty) {
        final uid = int.parse(uidStr);
        return " @${nameMap[uid] ?? uidStr} ";
      }
      return '';
    }, onNonMatch: (String text) {
      return text;
    });

    return text;
  }

  static Future<String> prepareDeviceInfo() async {
    String device;

    if (Platform.isIOS) {
      String? info = (await DeviceInfoPlugin().iosInfo).identifierForVendor;
      info = await _setGetDeviceId(deviceId: info);
      device = "iOS:$info";
    } else if (Platform.isAndroid) {
      String? info = (await AndroidId().getId());
      info = await _setGetDeviceId(deviceId: info);
      device = "Android:$info";
    } else {
      String info = await _setGetDeviceId();
      device = "Mobile:$info";
    }

    App.logger.info("Device Info: $device");

    return device;
  }

  /// Renew access token and refresh token, and do related data storage.
  static Future<bool> renewAuthToken({bool forceRefresh = false}) async {
    if (isRenewingToken) {
      return _tokenCompleter.future;
    }

    _tokenCompleter = Completer();
    isRenewingToken = true;
    App.app.statusService?.fireTokenLoading(TokenStatus.connecting);

    try {
      if (App.app.userDb == null) {
        App.app.statusService?.fireTokenLoading(TokenStatus.disconnected);

        _tokenCompleter.complete(false);
        isRenewingToken = false;
        return _tokenCompleter.future;
      }

      // Check whether old token expires:
      if (!forceRefresh) {
        final oldTokenExpiresAt =
            App.app.userDb!.updatedAt + App.app.userDb!.expiredIn * 1000;
        final now = DateTime.now().millisecondsSinceEpoch;

        // If token is still valid (need to update 60s before it actually expires),
        // return true.
        if (now < oldTokenExpiresAt - 60000) {
          App.app.statusService?.fireTokenLoading(TokenStatus.successful);
          App.logger
              .config("Token is still valid. ExpiresAt: $oldTokenExpiresAt");

          _tokenCompleter.complete(true);
          isRenewingToken = false;
          return _tokenCompleter.future;
        }
      }

      final req = TokenRenewRequest(
          App.app.userDb!.token, App.app.userDb!.refreshToken);

      final tokenApi = TokenApi();
      final res = await tokenApi.renewToken(req);

      if (res.statusCode == 200 && res.data != null) {
        App.logger.config("Token Refreshed.");
        final data = res.data!;
        final token = data.token;
        final refreshToken = data.refreshToken;
        final expiredIn = data.expiredIn;

        await _renewAuthDataInUserDb(token, refreshToken, expiredIn);

        _tokenCompleter.complete(true);
        isRenewingToken = false;
        return _tokenCompleter.future;
      } else {
        if (res.statusCode == 401 || res.statusCode == 403) {
          App.logger
              .severe("Renew Token Failed, Status code: ${res.statusCode}");

          App.app.statusService?.fireTokenLoading(TokenStatus.unauthorized);

          App.logger
              .severe("Renew Token Failed, Status code: ${res.statusCode}");

          _tokenCompleter.complete(false);
          isRenewingToken = false;
          return _tokenCompleter.future;
        }
      }
    } catch (e) {
      App.logger.severe(e);
      App.app.statusService?.fireTokenLoading(TokenStatus.disconnected);
    }

    _tokenCompleter.complete(false);
    isRenewingToken = false;
    return _tokenCompleter.future;
  }

  static Future<void> _renewAuthDataInUserDb(
      String token, String refreshToken, int expiredIn) async {
    final status = await StatusMDao.dao.getStatus();
    if (status == null) {
      App.logger.severe("Empty UserDbId in Status Db");
      return;
    }

    final newUserDbM = await UserDbMDao.dao
        .updateAuth(status.userDbId, token, refreshToken, expiredIn);
    App.app.userDb = newUserDbM;
    App.app.statusService?.fireTokenLoading(TokenStatus.successful);
  }

  /// Set or get device id from shared preference.
  ///
  /// If there is an old device id, return it.
  /// If there is no old device id, and [deviceId] is empty, generate a new
  /// device id and save it to shared preference.
  /// If [deviceId] is not empty, save it to shared preference and return it.
  static Future<String> _setGetDeviceId({String? deviceId}) async {
    final oldDeviceId = await SharedPreferenceHelper.getString("device_id");

    if (oldDeviceId != null && oldDeviceId.isNotEmpty) {
      return oldDeviceId;
    } else if (deviceId == null || deviceId.isEmpty) {
      deviceId = uuid();
    }
    await SharedPreferenceHelper.setString("device_id", deviceId);
    return deviceId;
  }

  /// Translate the number of seconds to minutes (hours or days).
  static String translateAutoDeletionSettingTime(
      int seconds, BuildContext context) {
    if (seconds == 0) {
      return AppLocalizations.of(context)!.off;
    } else if (seconds >= 1 && seconds < 60) {
      if (seconds == 1) {
        return "1 ${AppLocalizations.of(context)!.second}";
      } else {
        return "$seconds ${AppLocalizations.of(context)!.seconds}";
      }
    } else if (seconds >= 60 && seconds < 3600) {
      final minute = seconds ~/ 60;
      if (minute == 1) {
        return "1 ${AppLocalizations.of(context)!.minute}";
      } else {
        return "$minute ${AppLocalizations.of(context)!.minutes}";
      }
    } else if (seconds >= 3600 && seconds < 86400) {
      final hour = seconds ~/ 3600;
      if (hour == 1) {
        return "1 ${AppLocalizations.of(context)!.hour}";
      } else {
        return "$hour ${AppLocalizations.of(context)!.hours}";
      }
    } else if (seconds >= 86400 && seconds < 604800) {
      final day = seconds ~/ 86400;
      if (day == 1) {
        return "1 ${AppLocalizations.of(context)!.day}";
      } else {
        return "$day ${AppLocalizations.of(context)!.days}";
      }
    } else {
      final week = seconds ~/ 604800;
      if (week == 1) {
        return "1 ${AppLocalizations.of(context)!.week}";
      } else {
        return "$week ${AppLocalizations.of(context)!.weeks}";
      }
    }
  }

  /// Get or update server information, including server name, description and
  /// logo image.
  static Future<ChatServerM?> getServerInfo(ChatServerM chatServerM) async {
    try {
      final fullUrl = chatServerM.fullUrl;
      final orgInfoRes = await AdminSystemApi(serverUrl: fullUrl).getOrgInfo();
      if (orgInfoRes.statusCode == 200 && orgInfoRes.data != null) {
        final orgInfo = orgInfoRes.data!;
        chatServerM.properties = ChatServerProperties(
            serverName: orgInfo.name, description: orgInfo.description ?? "");

        final logoRes = await ResourceApi(serverUrl: fullUrl).getOrgLogo();
        if (logoRes.statusCode == 200 && logoRes.data != null) {
          chatServerM.logo = logoRes.data!;
        }

        final adminLoginRes =
            await AdminLoginApi(serverUrl: fullUrl).getConfig();
        if (adminLoginRes.statusCode == 200 && adminLoginRes.data != null) {
          chatServerM.properties = ChatServerProperties(
              serverName: orgInfo.name,
              description: orgInfo.description ?? "",
              config: adminLoginRes.data);
        }

        final adminSysCommonInfo =
            await AdminSystemApi(serverUrl: fullUrl).getCommonInfo();
        if (adminSysCommonInfo.statusCode == 200 &&
            adminSysCommonInfo.data != null) {
          final commonInfo = adminSysCommonInfo.data!;
          chatServerM.properties = ChatServerProperties(
              serverName: orgInfo.name,
              description: orgInfo.description ?? "",
              config: adminLoginRes.data,
              commonInfo: commonInfo);
        }

        chatServerM.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await ChatServerDao.dao.addOrUpdate(chatServerM);

        return chatServerM;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  static void _showInvalidLinkWarning(BuildContext context) {
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

  static Future<void> _showNetworkErrorWarning(BuildContext context) async {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.networkError,
        content: AppLocalizations.of(context)!.networkErrorDes,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.ok,
              action: () {
                Navigator.pop(context);
              })
        ]);
  }
}

class QrScanResult {
  ChatServerM? chatServerM;
  String? magicToken;
  Uri? uri;
  InvitationLinkPreparationStatus status;

  QrScanResult(
      {this.chatServerM, this.magicToken, this.uri, required this.status});
}
