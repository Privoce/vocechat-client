import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/admin/system/sys_common_ext_settings.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/user_settings.dart';
import 'package:vocechat_client/dao/init_dao/user_settings.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/auto_delete_settings_tile.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/channel_info_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/channel_invite_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/owner_transfer_sheet.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/setting_members_tile.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/pinned_msg/pinned_msg_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/saved_page.dart';
import 'package:vocechat_client/ui/widgets/app_banner_button.dart';
import 'package:vocechat_client/ui/widgets/app_busy_dialog.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class ChannelSettingsPage extends StatefulWidget {
  final ValueNotifier<GroupInfoM> groupInfoNotifier;

  ChannelSettingsPage({required this.groupInfoNotifier});

  @override
  State<ChannelSettingsPage> createState() => _ChannelSettingsPageState();
}

class _ChannelSettingsPageState extends State<ChannelSettingsPage> {
  final ValueNotifier<bool> isLeaveBusy = ValueNotifier(false);
  final ValueNotifier<bool> isDeleteBusy = ValueNotifier(false);
  final ValueNotifier<bool> isMuteBusy = ValueNotifier(false);

  final ValueNotifier<bool> _isBusy = ValueNotifier(false);

  final ValueNotifier<bool> _isMuted = ValueNotifier(false);
  final ValueNotifier<bool> _pinned = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    final groupSettings = GroupSettings.fromUserSettings(
        globals.userSettings.value, widget.groupInfoNotifier.value.gid);
    _isMuted.value = groupSettings.enableMute;
    _pinned.value = groupSettings.pinnedAt > 0;
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
            ListView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              children: [
                _buildChannelInfo(context),
                _buildMsgActions(),
                _buildInvitition(context),
                _buildSwitches(),
                // _buildPin(),
                _buildBurnAfterReading(context),
                if (shouldShowMemberTile())
                  ValueListenableBuilder<GroupInfoM>(
                      valueListenable: widget.groupInfoNotifier,
                      builder: (context, groupInfoM, _) {
                        return SettingMembersTile(
                            groupInfoMNotifier: widget.groupInfoNotifier);
                      }),
                _buildChannelVisibiliy(),
                _buildBtns()
              ],
            ),
            BusyDialog(busy: _isBusy)
          ],
        ));
  }

  Widget _buildChannelInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ValueListenableBuilder<GroupInfoM>(
          valueListenable: widget.groupInfoNotifier,
          builder: (context, groupInfoM, _) {
            bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
            bool isOwner = App.app.userDb?.uid == groupInfoM.groupInfo.owner;

            final info = groupInfoM.groupInfo;
            return AvatarInfoTile(
              avatar: VoceChannelAvatar.channel(
                  groupInfoM: groupInfoM, size: VoceAvatarSize.s84),
              title: info.name,
              subtitle: info.description,
              enableEdit: isAdmin || isOwner,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) {
                    return ChannelInfoPage(widget.groupInfoNotifier);
                  },
                ));
              },
            );
          }),
    );
  }

  Widget _buildPinIcon() {
    return ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier,
        builder: (context, groupInfoM, _) {
          final pinIcon =
              Icon(AppIcons.pin, size: 24, color: AppColors.grey500);
          if (groupInfoM.groupInfo.pinnedMessages.isEmpty) {
            return pinIcon;
          }
          return Stack(
            children: [
              Padding(padding: const EdgeInsets.only(right: 5), child: pinIcon),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                        groupInfoM.groupInfo.pinnedMessages.length.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget _buildMsgActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: BannerTileGroup(
        bannerTileList: [
          BannerTile(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
                return PinnedMsgPage(widget.groupInfoNotifier);
              }))).then((value) {
                // _pinCountFuture);
              });
            },
            title: AppLocalizations.of(context)!.pin,
            trailing: ValueListenableBuilder<GroupInfoM>(
                valueListenable: widget.groupInfoNotifier,
                builder: (context, groupInfoM, _) {
                  if (groupInfoM.groupInfo.pinnedMessages.isEmpty) {
                    return SizedBox.shrink();
                  }
                  return Text(
                      groupInfoM.groupInfo.pinnedMessages.length.toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 17,
                          color: AppColors.labelColorLightSec));
                }),
          ),
          BannerTile(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: ((context) {
                  return SavedItemPage(gid: widget.groupInfoNotifier.value.gid);
                })));
              },
              title: AppLocalizations.of(context)!.savedItems)
        ],
      ),
    );
  }

  Widget _buildInvitition(BuildContext context) {
    bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
    bool isOwner =
        App.app.userDb?.uid == widget.groupInfoNotifier.value.groupInfo.owner;

    if (isAdmin || isOwner) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: BannerTileGroup(
          bannerTileList: [
            BannerTile(
                onTap: () async {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: ((context) {
                    return ChannelInvitePage(
                        widget.groupInfoNotifier.value.gid);
                  })));
                },
                title: AppLocalizations.of(context)!.invitationLink),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildSwitches() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: BannerTileGroup(
        bannerTileList: [
          BannerTile(
            title: AppLocalizations.of(context)!.muteNotification,
            keepTrailingArrow: false,
            trailing: ValueListenableBuilder<bool>(
                valueListenable: _isMuted,
                builder: (context, isMuted, _) {
                  return CupertinoSwitch(
                    value: isMuted,
                    activeColor: AppColors.primary400,
                    onChanged: (value) {
                      _changeMuteSettings(value);
                    },
                  );
                }),
          ),
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
        ],
      ),
    );
  }

  Widget _buildBurnAfterReading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ValueListenableBuilder<UserSettings>(
          valueListenable: globals.userSettings,
          builder: (context, userSettings, _) {
            final initExpTime = GroupSettings.fromUserSettings(
                    userSettings, widget.groupInfoNotifier.value.gid)
                .burnAfterReadSecond;
            return BannerTileGroup(
              bannerTileList: [
                BannerTile(
                  onTap: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AutoDeleteSettingsPage(
                          initExpTime: initExpTime,
                          onSubmit: _changeBurnAfterReadingSettings),
                    ));
                  },
                  title: AppLocalizations.of(context)!.autoDeleteMessage,
                  trailing: Text(
                      SharedFuncs.translateAutoDeletionSettingTime(
                          initExpTime, context),
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 17,
                          color: AppColors.labelColorLightSec)),
                ),
              ],
            );
          }),
    );
  }

  Future<void> _changeMuteSettings(bool value) async {
    showBusyDialog();

    try {
      if (value) {
        await _mute().then((value) async {
          if (value) {
            await UserSettingsDao()
                .updateGroupSettings(widget.groupInfoNotifier.value.gid,
                    mute: true)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
            _isMuted.value = true;
          } else {
            showNetworkErrorBar();
          }
        });
      } else {
        await _unMute().then((value) async {
          if (value) {
            await UserSettingsDao()
                .updateGroupSettings(widget.groupInfoNotifier.value.gid,
                    mute: false)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
            _isMuted.value = false;
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

  Future<void> _changePinSettings(bool value) async {
    showBusyDialog();

    try {
      if (value) {
        await _pin().then((value) async {
          if (value) {
            await UserSettingsDao()
                .updateGroupSettings(widget.groupInfoNotifier.value.gid,
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
                .updateGroupSettings(widget.groupInfoNotifier.value.gid,
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

  Future<bool> _changeBurnAfterReadingSettings(int expiresIn) async {
    final res = await UserApi().postBurnAfterReadingSetting(
        expiresIn: expiresIn, gid: widget.groupInfoNotifier.value.gid);
    if (res.statusCode == 200) {
      await UserSettingsDao()
          .updateGroupSettings(widget.groupInfoNotifier.value.gid,
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

  Widget _buildChannelVisibiliy() {
    return ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier,
        builder: (context, groupInfoM, _) {
          bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
          // bool isOwner = App.app.userDb?.uid == groupInfoM.groupInfo.owner;
          // bool isPublic = groupInfoM.isPublic;
          bool showSwitch = false;

          showSwitch = isAdmin;

          if (showSwitch) {
            final isPublic = groupInfoM.isPublic;
            return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: BannerTileGroup(bannerTileList: [
                  BannerTile(
                    title: AppLocalizations.of(context)!.publicChannel,
                    keepTrailingArrow: false,
                    trailing: CupertinoSwitch(
                        value: isPublic,
                        activeColor: AppColors.primary400,
                        onChanged: (isPublic) async {
                          await _changeChannelVisibility(isPublic);
                          setState(() {});
                        }),
                  )
                ]));
          }
          return SizedBox.shrink();
        });
  }

  Future<void> _changeChannelVisibility(bool isPublic) async {
    final toPublicTitle =
        AppLocalizations.of(context)!.privateChannelToPublicTitle;
    final toPublicText =
        AppLocalizations.of(context)!.privateChannelToPublicContent;

    final toPrivateTitle =
        AppLocalizations.of(context)!.publicChannelToPrivateTitle;
    final toPrivateText =
        AppLocalizations.of(context)!.publicChannelToPrivateContent;

    String title = isPublic ? toPublicTitle : toPrivateTitle;
    String text = isPublic ? toPublicText : toPrivateText;

    await showAppAlert(
        context: context,
        title: title,
        content: text,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.of(context).pop()),
        ],
        primaryAction: AppAlertDialogAction(
            isDangerAction: true,
            text: AppLocalizations.of(context)!.continueStr,
            action: () async {
              await _apiChangeChannelVisibility(isPublic);
              Navigator.of(context).pop();
            }));
  }

  Future<bool> _apiChangeChannelVisibility(bool isPublic) async {
    final gid = widget.groupInfoNotifier.value.gid;
    final api = GroupApi();

    try {
      final res = await api.changeType(gid, isPublic);
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }

    return false;
  }

  Widget _buildBtns() {
    // Owner / admin has 2 btns: leave & delete;
    // When the owner is leaving, ask for a ownership transfer.
    // Members have 1 btn: Leave.

    // Members of public channels are not allowed to leave.
    // Only admins could delete public channels.

    return ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier,
        builder: (context, groupInfoM, _) {
          bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
          bool isOwner = App.app.userDb?.uid == groupInfoM.groupInfo.owner;

          bool showDeleteBtn = isAdmin || isOwner;
          bool showLeaveBtn = !groupInfoM.isPublic;

          return Column(
            children: [
              if (showLeaveBtn)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ValueListenableBuilder<bool>(
                      valueListenable: isLeaveBusy,
                      builder: (context, leaveBusy, _) {
                        return AppBannerButton(
                          onTap: () => _onLeave(isOwner),
                          titleWidget: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (leaveBusy) CupertinoActivityIndicator(),
                              if (leaveBusy) SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.leaveChannel,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    color: AppColors.systemRed),
                              )
                            ],
                          ),
                        );
                      }),
                ),
              if (showDeleteBtn)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ValueListenableBuilder(
                      valueListenable: isDeleteBusy,
                      builder: (context, isDeleting, _) {
                        return AppBannerButton(
                            title: AppLocalizations.of(context)!.deleteChannel,
                            onTap: _onDelete);
                      }),
                ),
            ],
          );
        });
  }

  /// SHOW member tile if
  /// 1. I am an admin, OR
  /// 2. I am the channel owner, OR
  /// 3. the onlyAdminCanSeeChannelMembers flag is FALSE.
  bool shouldShowMemberTile() {
    if (App.app.userDb?.userInfo.isAdmin == true ||
        widget.groupInfoNotifier.value.groupInfo.owner ==
            App.app.userDb?.userInfo.uid) {
      return true;
    }

    try {
      final extSettings = AdminSystemCommonExtSettings.fromJson(jsonDecode(
          App.app.chatServerM.properties.commonInfo?.extSettings ?? ""));
      return extSettings.onlyAdminCanSeeChannelMembers != true;
    } catch (e) {
      App.logger.warning("Json decode failed, return FALSE by default.");
    }

    return false;
  }

  void _onLeave(bool isOwner) async {
    String title = AppLocalizations.of(context)!.leaveChannel;
    String content = AppLocalizations.of(context)!.leaveChannelWarningDes;

    if (isOwner) {
      content +=
          "\n${AppLocalizations.of(context)!.leaveChannelTransferOwnerDes}";
    }

    await showAppAlert(
        context: context,
        title: title,
        content: content,
        primaryAction: AppAlertDialogAction(
          text: isOwner
              ? AppLocalizations.of(context)!.continueStr
              : AppLocalizations.of(context)!.leave,
          isDangerAction: !isOwner,
          action: () async {
            Navigator.pop(context);
            if (isOwner) {
              _transferOwner(isOwner);
            } else {
              _leave();
            }
          },
        ),
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.pop(context))
        ]);
  }

  void _onDelete() async {
    String title = AppLocalizations.of(context)!.deleteChannel;
    String content = AppLocalizations.of(context)!.deleteChannelWarningDes;

    await showAppAlert(
        context: context,
        title: title,
        content: content,
        primaryAction: AppAlertDialogAction(
          text: AppLocalizations.of(context)!.delete,
          isDangerAction: true,
          action: () async {
            Navigator.pop(context);
            _delete();
          },
        ),
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.pop(context))
        ]);
  }

  Future<void> _transferOwner(bool isOwner) async {
    if (!isOwner) {
      return;
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8))),
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.7,
            child:
                OwnerTransferSheet(groupInfoM: widget.groupInfoNotifier.value),
          );
        });
  }

  Future<bool> _leave() async {
    isLeaveBusy.value = true;
    int gid = widget.groupInfoNotifier.value.gid;
    try {
      final groupApi = GroupApi();
      final res = await groupApi.leaveGroup(widget.groupInfoNotifier.value.gid);
      if (res.statusCode == 200) {
        await FileHandler.singleton
            .deleteChatDirectory(SharedFuncs.getChatId(gid: gid)!);
        await ChatMsgDao().deleteMsgByGid(gid);

        isLeaveBusy.value = false;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    isLeaveBusy.value = false;
    return false;
  }

  Future<bool> _delete() async {
    isDeleteBusy.value = true;
    int gid = widget.groupInfoNotifier.value.gid;
    try {
      final groupApi = GroupApi();
      final res = await groupApi.delete(widget.groupInfoNotifier.value.gid);
      if (res.statusCode == 200) {
        await FileHandler.singleton
            .deleteChatDirectory(SharedFuncs.getChatId(gid: gid)!);
        await ChatMsgDao().deleteMsgByGid(gid);
        await GroupInfoDao().deleteGroupByGid(gid);
        isDeleteBusy.value = false;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    isDeleteBusy.value = false;
    return false;
  }

  Future<bool> _mute({int? expiredAt}) async {
    final reqMap = {
      "add_groups": [
        {"gid": widget.groupInfoNotifier.value.gid}
      ]
    };

    try {
      final userApi = UserApi();
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> _unMute() async {
    final reqMap = {
      "remove_groups": [widget.groupInfoNotifier.value.gid]
    };
    try {
      final userApi = UserApi();
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> _pin() async {
    try {
      final res =
          await UserApi().pinChat(gid: widget.groupInfoNotifier.value.gid);
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
          await UserApi().unpinChat(gid: widget.groupInfoNotifier.value.gid);
      if (res.statusCode == 200) {
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
