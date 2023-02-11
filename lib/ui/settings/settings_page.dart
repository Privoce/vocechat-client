import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';

import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/settings/child_pages/firebase_settings_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/language_setting_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/reload_notification_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/server_info_settings_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/settings_about_page.dart';
import 'package:vocechat_client/ui/settings/settings_bar.dart';
import 'package:vocechat_client/ui/settings/child_pages/userinfo_setting_page.dart';
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
                  _buildLanguage(context),
                  _buildPushNotificationToken(context),
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

  Widget _buildLanguage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: BannerTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
              return LanguageSettingPage();
            })));
          },
          title: AppLocalizations.of(context)!.language),
    );
  }

  Widget _buildPushNotificationToken(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: BannerTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
              return ReloadNotificationPage();
            })));
          },
          title: AppLocalizations.of(context)!.resetFcmToken),
    );
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
            title: AppLocalizations.of(context)!.clearLocalData),
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
        content: AppLocalizations.of(context)!.logoutWarningWithQM,
        primaryAction: AppAlertDialogAction(
            text: AppLocalizations.of(context)!.logOut,
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
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.pop(context)),
        ]);
  }

  void _onResetDbTapped(BuildContext context) async {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.clearLocalData,
        content: AppLocalizations.of(context)!.clearLocalDataContent,
        primaryAction: AppAlertDialogAction(
            text: AppLocalizations.of(context)!.ok,
            isDangerAction: true,
            action: _onReset),
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.pop(context))
        ]);
  }

  void _onDeleteAccountTapped(BuildContext context) async {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.deleteAccountWarning,
        content: AppLocalizations.of(context)!.deleteAccountWarningContent,
        primaryAction: AppAlertDialogAction(
            isDangerAction: true,
            text: AppLocalizations.of(context)!.delete,
            action: () async {
              final api = UserApi();
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
                    title:
                        AppLocalizations.of(context)!.deleteAccountFailWarning,
                    content: AppLocalizations.of(context)!
                        .deleteAccountFailWarningContent,
                    actions: [
                      AppAlertDialogAction(
                          text: AppLocalizations.of(context)!.ok,
                          action: () => Navigator.of(context).pop(context))
                    ]);
              }
            }),
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
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

  Future<void> _onUser(UserInfoM userInfoM, EventActions action) async {
    if (userInfoM.uid == App.app.userDb?.uid) {
      userInfoNotifier.value = userInfoM;

      // Add [notifyListeners()] to avoid no UI response on avatar changed.
      userInfoNotifier.notifyListeners();
    }
  }
}
