import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';

import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/pulse_widgets/pulse_settings_my_info_page.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/settings/child_pages/firebase_settings_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/language_setting_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/server_info_settings_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/settings_about_page.dart';
import 'package:vocechat_client/ui/settings/settings_bar.dart';
import 'package:vocechat_client/ui/settings/child_pages/userinfo_setting_page.dart';
import 'package:vocechat_client/ui/widgets/app_banner_button.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';

import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class PulseSettingsPage extends StatefulWidget {
  static const route = "/settings";

  const PulseSettingsPage({Key? key}) : super(key: key);

  @override
  State<PulseSettingsPage> createState() => _PulseSettingsPageState();
}

class _PulseSettingsPageState extends State<PulseSettingsPage> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPulseUserInfo(),
        _buildMyInfo()
        // _buildServer(context),
        // _buildLanguage(context),
        // _buildPushNotificationToken(context),
        // _buildAbout(),
        // SizedBox(height: 8),
        // _buildButtons(context)
      ],
    );
  }

  Widget _buildPulseUserInfo() {
    final textColor = Colors.grey[300];
    const titleFontSize = 22.0;
    const subtitleFontSize = 16.0;

    return Container(
      color: Colors.blue[400],
      width: double.maxFinite,
      child: ValueListenableBuilder<UserInfoM?>(
          valueListenable: userInfoNotifier,
          builder: (context, userInfoM, _) {
            if (userInfoM != null) {
              final userInfo = userInfoM.userInfo;

              return CupertinoButton(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: ((context) {
                    return PulseSettingsMyInfoPage(
                        userInfoNotifier: userInfoNotifier);
                  })));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoceUserAvatar.user(
                        userInfoM: userInfoM,
                        size: VoceAvatarSize.s84,
                        enableOnlineStatus: false),
                    SizedBox(height: 8),
                    Text(userInfo.name,
                        style: TextStyle(
                            fontSize: titleFontSize, color: textColor)),
                    SizedBox(height: 8),
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text("ID: ${userInfo.uid}",
                                style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: textColor)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.qr_code,
                                color: textColor, size: subtitleFontSize),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(CupertinoIcons.chevron_right,
                                size: subtitleFontSize, color: textColor),
                          )
                        ]),
                    SizedBox(height: 16),
                  ],
                ),
              );

              // return AvatarInfoTile(
              //   avatar: VoceUserAvatar.user(
              //       userInfoM: userInfoM,
              //       size: VoceAvatarSize.s84,
              //       enableOnlineStatus: false),
              //   titleWidget: Text(userInfo.name,
              //       style:
              //           TextStyle(fontSize: titleFontSize, color: textColor)),
              //   subtitleWidget: Padding(
              //     padding: const EdgeInsets.only(top: 4),
              //     child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         mainAxisAlignment: MainAxisAlignment.spaceAround,
              //         children: [
              //           Padding(
              //             padding: const EdgeInsets.symmetric(horizontal: 4),
              //             child: Text("ID: ${userInfo.uid}",
              //                 style: TextStyle(
              //                     fontSize: subtitleFontSize,
              //                     color: textColor)),
              //           ),
              //           Padding(
              //             padding: const EdgeInsets.symmetric(horizontal: 4),
              //             child: Icon(Icons.qr_code,
              //                 color: textColor, size: subtitleFontSize),
              //           ),
              //           Padding(
              //             padding: const EdgeInsets.symmetric(horizontal: 4),
              //             child: Icon(CupertinoIcons.chevron_right,
              //                 size: subtitleFontSize, color: textColor),
              //           )
              //         ]),
              //   ),
              //   enableEdit: true,
              //   onTap: () {
              //     Navigator.of(context)
              //         .push(MaterialPageRoute(builder: ((context) {
              //       return UserInfoSettingPage(userInfoNotifier);
              //     })));
              //   },
              // );
            } else {
              return AvatarInfoTile(
                  avatar: CircleAvatar(
                    radius: 40,
                  ),
                  title: "");
            }
          }),
    );
  }

  Widget _buildMyInfo() {
    return BannerTileGroup(bannerTileList: [
      BannerTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
              return PulseSettingsMyInfoPage(
                  userInfoNotifier: userInfoNotifier);
            })));
          },
          title: AppLocalizations.of(context)!.settingsPageMyInfo),
      BannerTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
              return SettingsAboutPage();
            })));
          },
          title: AppLocalizations.of(context)!.settingsPageAbout),
      BannerTile(
          onTap: () {
            // Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
            //   return UserInfoSettingPage(userInfoNotifier);
            // })));
          },
          title: AppLocalizations.of(context)!.settingsPageLogout),
    ]);
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
