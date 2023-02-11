import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/auto_delete_settings_tile.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/channel_info_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/owner_transfer_sheet.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/saved_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/setting_members_tile.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/pinned_msg/pinned_msg_page.dart';
import 'package:vocechat_client/ui/widgets/app_banner_button.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/channel_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildChannelInfo(context),
                SizedBox(height: 8),
                _buildMsgActions(),
                SizedBox(height: 8),
                _buildBurnAfterReading(context),
                SizedBox(height: 8),
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
          ),
        ));
  }

  Widget _buildChannelInfo(BuildContext context) {
    return ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier,
        builder: (context, groupInfoM, _) {
          bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
          bool isOwner = App.app.userDb?.uid == groupInfoM.groupInfo.owner;

          final info = groupInfoM.groupInfo;
          return AvatarInfoTile(
            avatar: ChannelAvatar(
                avatarSize: AvatarSize.s84,
                isPublic: groupInfoM.isPublic == 1,
                avatarBytes: groupInfoM.avatar),
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
        });
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
                      color: AppColors.primary400,
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
    return BannerTileGroup(
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
              Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
                return SavedItemPage(gid: widget.groupInfoNotifier.value.gid);
              })));
            },
            title: AppLocalizations.of(context)!.savedItems)
      ],
    );
  }

  Widget _buildBurnAfterReading(BuildContext context) {
    return ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier,
        builder: (context, groupInfoM, _) {
          final initExpTime = groupInfoM.properties.burnAfterReadSecond;
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
                    translateAutoDeletionSettingTime(initExpTime, context),
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 17,
                        color: AppColors.labelColorLightSec)),
              ),
            ],
          );
        });
  }

  Future<bool> _changeBurnAfterReadingSettings(int expiresIn) async {
    final res = await UserApi().postBurnAfterReadingSetting(
        expiresIn: expiresIn, gid: widget.groupInfoNotifier.value.gid);
    if (res.statusCode == 200) {
      final groupInfoM = await GroupInfoDao().updateProperties(
          widget.groupInfoNotifier.value.gid,
          burnAfterReadSecond: expiresIn);
      if (groupInfoM != null) {
        App.app.chatService.fireChannel(groupInfoM, EventActions.update);
        return true;
      }
    }
    return false;
  }

  Widget _buildChannelVisibiliy() {
    return ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier,
        builder: (context, groupInfoM, _) {
          bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
          bool isOwner = App.app.userDb?.uid == groupInfoM.groupInfo.owner;
          bool isPublic = groupInfoM.isPublic == 1;
          bool showSwitch = false;

          if (isPublic) {
            showSwitch = isAdmin;
          } else {
            showSwitch = isAdmin || isOwner;
          }

          if (showSwitch) {
            final isPublic = groupInfoM.isPublic == 0 ? false : true;
            return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: BannerTileGroup(bannerTileList: [
                  BannerTile(
                    title: AppLocalizations.of(context)!.publicChannel,
                    keepArrow: false,
                    trailing: CupertinoSwitch(
                        value: isPublic,
                        onChanged: (_isPublic) async {
                          await _changeChannelVisibility(_isPublic);
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
    final api = GroupApi(App.app.chatServerM.fullUrl);

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
          bool showLeaveBtn = groupInfoM.isPublic != 1;

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

  void _onLeave(bool isOwner) async {
    String title = AppLocalizations.of(context)!.leaveChannel;
    String content = AppLocalizations.of(context)!.leaveChannelWarningDes;

    if (isOwner) {
      content +=
          "\n" + AppLocalizations.of(context)!.leaveChannelTransferOwnerDes;
    }

    await showAppAlert(
        context: context,
        title: title,
        content: content,
        primaryAction: AppAlertDialogAction(
          text: isOwner
              ? AppLocalizations.of(context)!.call
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
      final groupApi = GroupApi(App.app.chatServerM.fullUrl);
      final res = await groupApi.leaveGroup(widget.groupInfoNotifier.value.gid);
      if (res.statusCode == 200) {
        await FileHandler.singleton.deleteChatDirectory(getChatId(gid: gid)!);
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
      final groupApi = GroupApi(App.app.chatServerM.fullUrl);
      final res = await groupApi.delete(widget.groupInfoNotifier.value.gid);
      if (res.statusCode == 200) {
        await FileHandler.singleton.deleteChatDirectory(getChatId(gid: gid)!);
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
        {"gid": widget.groupInfoNotifier.value.gid, "expired_at": expiredAt}
      ]
    };

    try {
      final userApi = UserApi();
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        await App.app.chatService.mute(
            gid: widget.groupInfoNotifier.value.gid, expiredAt: expiredAt);
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
        await App.app.chatService
            .mute(gid: widget.groupInfoNotifier.value.gid, unmute: true);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  // Future<void> _onGroup(GroupInfoM groupInfoM, EventActions action) async {
  //   if (groupInfoM.gid == widget.groupInfoNotifier.gid) {
  //     switch (action) {
  //       case EventActions.update:
  //         widget.groupInfoNotifier = groupInfoM;
  //         setState(() {});
  //         break;
  //       default:
  //     }
  //   }
  // }
}
