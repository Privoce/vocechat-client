import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/user_settings.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/init_dao/user_settings.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/auto_delete_settings_tile.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/saved_page.dart';
import 'package:vocechat_client/ui/widgets/app_busy_dialog.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class DmSettingsPage extends StatefulWidget {
  final ValueNotifier<UserInfoM> userInfoNotifier;

  DmSettingsPage({required this.userInfoNotifier});

  @override
  State<DmSettingsPage> createState() => _DmSettingsPageState();
}

class _DmSettingsPageState extends State<DmSettingsPage> {
  final ValueNotifier<bool> _isBusy = ValueNotifier(false);

  final ValueNotifier<bool> _pinned = ValueNotifier(false);
  final ValueNotifier<bool> _muted = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    final dmSettings = DmSettings.fromUserSettings(
        globals.userSettings.value, widget.userInfoNotifier.value.uid);
    _muted.value = dmSettings.enableMute;
    _pinned.value = dmSettings.pinnedAt > 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showBusyDialog() {
    _isBusy.value = true;
  }

  void dismissBusyDialog() {
    _isBusy.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(242, 244, 247, 1),
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: Stack(
        children: [
          ListView(children: [
            _buildDmInfo(context),
            SizedBox(height: 8),
            _buildItems(widget.userInfoNotifier.value, context)
          ]),
          BusyDialog(busy: _isBusy)
        ],
      ),
    );
  }

  Widget _buildDmInfo(BuildContext context) {
    return ValueListenableBuilder<UserInfoM>(
        valueListenable: widget.userInfoNotifier,
        builder: (context, userInfoM, _) {
          final userInfo = userInfoM.userInfo;
          return AvatarInfoTile(
            avatar: VoceUserAvatar.user(
                userInfoM: userInfoM, size: VoceAvatarSize.s60),
            title: userInfo.name,
            subtitle: userInfo.email,
          );
        });
  }

  Widget _buildItems(UserInfoM userInfoM, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          BannerTileGroup(bannerTileList: [
            BannerTile(
              title: AppLocalizations.of(context)!.savedItems,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: ((context) {
                  return SavedItemPage(uid: widget.userInfoNotifier.value.uid);
                })));
              },
            )
          ]),
          SizedBox(height: 8),
          BannerTileGroup(bannerTileList: [
            BannerTile(
              title: AppLocalizations.of(context)!.muteNotification,
              keepTrailingArrow: false,
              trailing: ValueListenableBuilder<bool>(
                  valueListenable: _muted,
                  builder: (context, muted, _) {
                    return CupertinoSwitch(
                        value: muted,
                        activeColor: AppColors.primary400,
                        onChanged: (muted) async {
                          showBusyDialog();

                          try {
                            if (muted) {
                              await _mute();
                              _muted.value = true;
                            } else {
                              await _unMute();
                              _muted.value = false;
                            }
                          } catch (e) {
                            App.logger.severe(e);
                          }

                          dismissBusyDialog();
                        });
                  }),
            )
          ]),
          BannerTile(
            title: AppLocalizations.of(context)!.pinChat,
            keepTrailingArrow: false,
            trailing: ValueListenableBuilder<bool>(
                valueListenable: _pinned,
                builder: (context, pinned, _) {
                  return CupertinoSwitch(
                    value: pinned,
                    activeColor: AppColors.primary400,
                    onChanged: (value) {
                      _changePinSettings(value);
                    },
                  );
                }),
          ),
          SizedBox(height: 8),
          if (widget.userInfoNotifier.value.uid != App.app.userDb?.uid)
            ValueListenableBuilder<UserSettings>(
                valueListenable: globals.userSettings,
                builder: (context, userSettings, _) {
                  // This is not the read burn_after_read, but is auto-deletion.
                  // Name is consistant with server names.
                  final burnAfterReadSecond = DmSettings.fromUserSettings(
                          userSettings, widget.userInfoNotifier.value.uid)
                      .burnAfterReadSecond;

                  return BannerTileGroup(bannerTileList: [
                    BannerTile(
                      title: AppLocalizations.of(context)!.autoDeleteMessage,
                      trailing: Text(
                          SharedFuncs.translateAutoDeletionSettingTime(
                              burnAfterReadSecond, context),
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: AppColors.labelColorLightSec)),
                      onTap: () async {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: ((context) {
                          return AutoDeleteSettingsPage(
                            initExpTime: burnAfterReadSecond,
                            onSubmit: _changeBurnAfterReadingSettings,
                          );
                        })));
                      },
                    )
                  ]);
                }),
        ],
      ),
    );
  }

  Future<bool> _changeBurnAfterReadingSettings(int expiresIn) async {
    final res = await UserApi().postBurnAfterReadingSetting(
        uid: widget.userInfoNotifier.value.uid, expiresIn: expiresIn);
    if (res.statusCode == 200) {
      await UserSettingsDao()
          .updateDmSettings(widget.userInfoNotifier.value.uid,
              burnAfterReadSecond: expiresIn)
          .then((value) {
        if (value != null) {
          globals.userSettings.value = value;
        }
      });
      return true;
    }

    return false;
  }

  Future<void> _changePinSettings(bool value) async {
    showBusyDialog();

    try {
      if (value) {
        await _pin().then((value) async {
          if (value) {
            await UserSettingsDao()
                .updateDmSettings(widget.userInfoNotifier.value.uid,
                    pinnedAt: DateTime.now().millisecondsSinceEpoch)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
            _pinned.value = true;
          } else {
            showNetworkErrorBar();
          }
        });
      } else {
        await _unpin().then((value) async {
          if (value) {
            await UserSettingsDao()
                .updateDmSettings(widget.userInfoNotifier.value.uid,
                    pinnedAt: 0)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
            _pinned.value = false;
          } else {
            showNetworkErrorBar();
          }
        });
      }
    } catch (e) {
      App.logger.severe(e);
    }

    dismissBusyDialog();
  }

  Future<bool> _pin() async {
    try {
      final res =
          await UserApi().pinChat(uid: widget.userInfoNotifier.value.uid);
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> _unpin() async {
    try {
      final res =
          await UserApi().unpinChat(uid: widget.userInfoNotifier.value.uid);
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }

    return false;
  }

  Future<bool> _mute({int? expiredAt}) async {
    final reqMap = {
      "add_users": [
        {"uid": widget.userInfoNotifier.value.uid, "expired_at": expiredAt}
      ]
    };

    try {
      final userApi = UserApi();
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        await UserSettingsDao()
            .updateDmSettings(widget.userInfoNotifier.value.uid,
                muteExpiredAt: null)
            .then((value) {
          if (value != null) {
            globals.userSettings.value = value;
          }
        });
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> _unMute() async {
    final reqMap = {
      "remove_mute_users": [widget.userInfoNotifier.value.uid]
    };

    try {
      final userApi = UserApi();
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        await UserSettingsDao()
            .updateDmSettings(widget.userInfoNotifier.value.uid,
                muteExpiredAt: 0)
            .then((value) {
          if (value != null) {
            globals.userSettings.value = value;
          }
        });
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  void showNetworkErrorBar() {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.networkError)));
  }
}
