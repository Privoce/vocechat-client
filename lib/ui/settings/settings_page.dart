import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vocechat_client/api/lib/admin_user_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:vocechat_client/ui/settings/firebase_settings_page.dart';
import 'package:vocechat_client/ui/settings/server_info_settings_page.dart';
import 'package:vocechat_client/ui/settings/settings_about_page.dart';
import 'package:vocechat_client/ui/settings/settings_bar.dart';
import 'package:vocechat_client/ui/settings/userinfo_setting_page.dart';
import 'package:vocechat_client/ui/widgets/app_banner_button.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';

import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';

import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingPage extends StatefulWidget {
  static const route = "/settings";

  SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  ValueNotifier<UserInfoM?> userInfoNotifier = ValueNotifier(null);
  ValueNotifier<bool> isBusy = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    getUserInfoM();
    App.app.chatService.subscribeUsers(_onUser);

    eventBus.on<UserChangeEvent>().listen((event) {
      getUserInfoM();
      App.app.chatService.subscribeUsers(_onUser);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeUsers(_onUser);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isBusy,
        builder: (context, busy, _) {
          return AbsorbPointer(
            absorbing: busy,
            child: Scaffold(
              appBar: SettingBar(),
              body: SafeArea(
                  child: ListView(
                children: [
                  _buildUserInfo(),
                  _buildServer(context),
                  _buildAbout(),
                  if (App.app.userDb?.userInfo.isAdmin ?? false)
                    // _buildConfigs(context),

                    SizedBox(height: 8),
                  _buildButtons(context)
                ],
              )),
            ),
          );
        });
  }

  Widget _buildUserInfo() {
    return ValueListenableBuilder<UserInfoM?>(
        valueListenable: userInfoNotifier,
        builder: (context, userInfoM, _) {
          if (userInfoM != null) {
            final userInfo = userInfoM.userInfo;
            return AvatarInfoTile(
              avatar: UserAvatar(
                  uid: userInfo.uid,
                  avatarSize: AvatarSize.s84,
                  name: userInfo.name,
                  avatarBytes: userInfoM.avatarBytes),
              title: userInfo.name,
              subtitle: userInfo.email,
              enableEdit: true,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: ((context) {
                  return UserInfoSettingPage(userInfoNotifier);
                })));
              },
            );
          } else {
            return AvatarInfoTile(
                avatar: CircleAvatar(
                  radius: 40,
                ),
                title: "");
          }
        });
  }

  Widget _buildServer(BuildContext context) {
    return BannerTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
            return ServerInfoSettingsPage();
          })));
        },
        header: AppLocalizations.of(context)!.settingsPageServer,
        footer: AppLocalizations.of(context)!.settingsPageServerFooter,
        title: AppLocalizations.of(context)!.settingsPageServerOverview);
  }

  Widget _buildConfigs(BuildContext context) {
    return BannerTile(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => FirebaseSettingPage()));
        },
        header: AppLocalizations.of(context)!.settingsPageConfig,
        footer: AppLocalizations.of(context)!.settingsPageConfigFooter,
        title: AppLocalizations.of(context)!.settingsPageConfigFirebase);
  }

  Widget _buildAbout() {
    // return BannerTile(
    //     title: AppLocalizations.of(context)!.settingsPageAbout,
    //     keepArrow: false,
    //     enableTap: false,
    //     trailing: FutureBuilder<String>(
    //         future: _getVersion(),
    //         builder: (context, snapshot) {
    //           if (snapshot.hasData) {
    //             return Text(snapshot.data!,
    //                 style: TextStyle(
    //                     fontSize: 15,
    //                     fontWeight: FontWeight.w400,
    //                     color: AppColors.grey500));
    //           } else {
    //             return SizedBox.shrink();
    //           }
    //         }));
    return BannerTile(
        title: AppLocalizations.of(context)!.settingsPageAbout,
        keepArrow: true,
        enableTap: true,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => SettingsAboutPage())),
        trailing: FutureBuilder<String>(
            future: _getVersion(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey500));
              } else {
                return SizedBox.shrink();
              }
            }));
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;
    // return version + "($buildNumber)";
    return version;
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8),
        AppBannerButton(
          title: AppLocalizations.of(context)!.switchServer,
          onTap: () {
            _onSwitchServerTapped();
          },
        ),
        SizedBox(height: 8),
        AppBannerButton(
          title: AppLocalizations.of(context)!.logOut,
          onTap: () {
            _onLogoutTapped(context);
          },
        ),
        SizedBox(height: 8),
        AppBannerButton(
            onTap: () {
              _onResetDbTapped(context);
            },
            title: AppLocalizations.of(context)!.settingsPageClearData),
        SizedBox(height: 8),
        if (App.app.userDb?.uid != 1)
          AppBannerButton(
            onTap: () => _onDeleteAccountTapped(context),
            title: AppLocalizations.of(context)!.deleteAccount,
          )
      ],
    );
  }

  void _onSwitchServerTapped() {
    Scaffold.of(context).openDrawer();
  }

  void _onLogoutTapped(BuildContext context) async {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.logOut,
        content: "Are you sure to log out?",
        primaryAction: AppAlertDialogAction(
            text: 'Log Out',
            isDangerAction: true,
            action: () async {
              isBusy.value = true;
              await App.app.authService?.logout().then((value) async {
                await App.app.changeUserAfterLogOut();
              });
              isBusy.value = false;
            }),
        actions: [
          AppAlertDialogAction(
              text: 'Cancel', action: () => Navigator.pop(context)),
        ]);
  }

  void _onResetDbTapped(BuildContext context) async {
    showAppAlert(
        context: context,
        title: "Clear Local Data",
        content:
            "VoceChat will be terminated. All your data will be deleted locally.",
        primaryAction: AppAlertDialogAction(
            text: "OK", isDangerAction: true, action: _onReset),
        actions: [
          AppAlertDialogAction(
              text: "Cancel", action: () => Navigator.pop(context, 'Cancel'))
        ]);
  }

  void _onDeleteAccountTapped(BuildContext context) async {
    showAppAlert(
        context: context,
        title: "Are you sure to delete account?",
        content:
            "All your data will be deleted locally. Your account information will be deleted on server, but message contents will still be visible to other users. This can not be undone.",
        primaryAction: AppAlertDialogAction(
            isDangerAction: true,
            text: "Delete",
            action: () async {
              final api = UserApi(App.app.chatServerM.fullUrl);
              final res = await api.delete();
              if (res.statusCode == 200) {
                App.app.authService!.selfDelete().then((value) async {
                  try {
                    await App.app.changeUserAfterLogOut();
                    // navigatorKey.currentState!.pop();
                  } catch (e) {
                    App.logger.severe(e);
                  }
                });
              } else {
                Navigator.of(context).pop(context);
                showAppAlert(
                    context: context,
                    title: "Account Deletion Failed",
                    content:
                        "Please try again later or contact admin for help.",
                    actions: [
                      AppAlertDialogAction(
                          text: "OK",
                          action: () => Navigator.of(context).pop(context))
                    ]);
              }
            }),
        actions: [
          AppAlertDialogAction(
              text: "Cancel",
              action: () {
                Navigator.of(context).pop(context);
              })
        ]);
  }

  void _onReset() async {
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
  }

  void getUserInfoM() async {
    final userInfoM = await UserInfoDao().getUserByUid(App.app.userDb!.uid);
    if (userInfoM != null) {
      userInfoNotifier.value = userInfoM;
    }
  }

  Future<void> _onUser(
      UserInfoM userInfoM, EventActions action, bool afterReady) async {
    if (userInfoM.uid == App.app.userDb?.uid) {
      userInfoNotifier.value = userInfoM;

      // Add [notifyListeners()] to avoid no UI response on avatar changed.
      userInfoNotifier.notifyListeners();
    }
  }
}
