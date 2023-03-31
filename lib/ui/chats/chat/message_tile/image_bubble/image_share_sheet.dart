import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/send_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';

import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/chat_selection_sheet.dart';

class ImageShareSheet extends StatefulWidget {
  final File imageFile;

  ImageShareSheet({required this.imageFile});

  @override
  State<ImageShareSheet> createState() => _ImageShareSheetState();
}

class _ImageShareSheetState extends State<ImageShareSheet> {
  final ValueNotifier<ButtonStatus> _saveBtnStatus =
      ValueNotifier(ButtonStatus.normal);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: SafeArea(
        child: SizedBox(
          height: 257,
          child: ListView(
            children: [
              _buildRecentChats(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child:
                    Divider(color: AppColors.grey600, indent: 8, endIndent: 8),
              ),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChats() {
    return SizedBox(
      height: 120,
      child: FutureBuilder<List<RecentChatData>>(
          future: _getRecentChats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data!.isNotEmpty) {
              final recentChats = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentChats.length,
                itemBuilder: (context, index) {
                  final chat = recentChats[index];
                  final avatarWidget = chat.isGroup
                      // ? ChannelAvatar(
                      //     avatarSize: VoceAvatarSize.s48,
                      //     avatarBytes: chat.groupInfoM!.avatar,
                      //     name: chat.title)
                      ? VoceChannelAvatar.channel(
                          groupInfoM: chat.groupInfoM!,
                          size: VoceAvatarSize.s48)
                      : UserAvatar(
                          avatarSize: VoceAvatarSize.s48,
                          name: chat.title,
                          avatarBytes: chat.userInfoM!.avatarBytes,
                          enableOnlineStatus: true);
                  // return _buildButtonChild(avatarWidget, chat.title);
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _forwardImageToChat(
                        uid: chat.userInfoM?.uid,
                        gid: chat.groupInfoM?.gid,
                        imageFile: widget.imageFile,
                        targetName: chat.title),
                    child: SizedBox(
                      width: 76,
                      height: 120,
                      child: Column(
                        children: [
                          SizedBox(height: 24),
                          avatarWidget,
                          SizedBox(height: 8),
                          Text(chat.title,
                              style: AppTextStyles.labelSmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return CupertinoActivityIndicator();
          }),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          _buildSaveButton(),
          CupertinoButton(
              padding: EdgeInsets.all(8),
              onPressed: _showChatSelectionSheet,
              child: _buildButtonChild(
                  Icon(AppIcons.forward, size: 32, color: Colors.white),
                  AppLocalizations.of(context)!.forwardAsImage)),
          CupertinoButton(
              padding: EdgeInsets.all(8),
              onPressed: _share,
              child: _buildButtonChild(
                  Icon(AppIcons.share, size: 32, color: Colors.white),
                  AppLocalizations.of(context)!.share))
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ValueListenableBuilder<ButtonStatus>(
        valueListenable: _saveBtnStatus,
        builder: (context, status, _) {
          Widget child;
          double size = 32;

          switch (status) {
            case ButtonStatus.normal:
              child = Icon(Icons.save_alt, color: Colors.white, size: size);
              break;
            case ButtonStatus.inProgress:
              child = CupertinoActivityIndicator(
                  radius: size / 2, color: Colors.white);
              break;
            case ButtonStatus.success:
              child = Icon(Icons.check, color: Colors.white, size: size);
              break;
            case ButtonStatus.error:
              child = Icon(CupertinoIcons.exclamationmark,
                  color: Colors.white, size: size);
              break;

            default:
              child = Icon(Icons.save_alt, color: Colors.white, size: size);
          }
          return CupertinoButton(
              padding: EdgeInsets.all(8),
              onPressed: status == ButtonStatus.normal ? _saveImage : null,
              child: _buildButtonChild(
                  child, AppLocalizations.of(context)!.save,
                  color: status == ButtonStatus.error
                      ? AppColors.errorRed
                      : AppColors.grey600));
        });
  }

  Widget _buildButtonChild(Widget child, String title, {Color? color}) {
    return SizedBox(
      width: 60,
      child: Column(children: [
        Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color ?? AppColors.grey600),
            child: child),
        Text(title,
            style: AppTextStyles.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  void _saveImage() async {
    _saveBtnStatus.value = ButtonStatus.inProgress;

    try {
      final result = await ImageGallerySaver.saveFile(widget.imageFile.path);
      if (result["isSuccess"]) {
        _saveBtnStatus.value = ButtonStatus.success;
        await Future.delayed(Duration(seconds: 2)).then((_) async {
          _saveBtnStatus.value = ButtonStatus.normal;
        });
        return;
      }
    } catch (e) {
      App.logger.severe(e);
    }

    _saveBtnStatus.value = ButtonStatus.error;
    await Future.delayed(Duration(seconds: 2)).then((_) async {
      _saveBtnStatus.value = ButtonStatus.normal;
    });
    _saveBtnStatus.value = ButtonStatus.normal;
    return;
  }

  void _showChatSelectionSheet() {
    Navigator.of(context).pop();

    // show chat list
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.7,
        child: ChatSelectionSheet(
            title: AppLocalizations.of(context)!.forwardTo,
            onSubmit: _forwardImage),
      ),
    );
  }

  void _forwardImage(
      ValueNotifier<List<int>> uidNotifier,
      ValueNotifier<List<int>> gidNotifier,
      ValueNotifier<ButtonStatus> btnStatus) async {
    btnStatus.value = ButtonStatus.inProgress;

    final uidList = uidNotifier.value;
    final gidList = gidNotifier.value;

    try {
      for (final uid in uidList) {
        SendService.singleton.sendMessage(
            uuid(), widget.imageFile.path, SendType.file,
            uid: uid);
      }

      for (final gid in gidList) {
        SendService.singleton.sendMessage(
            uuid(), widget.imageFile.path, SendType.file,
            gid: gid);
      }
    } catch (e) {
      App.logger.severe(e);
    }

    btnStatus.value = ButtonStatus.normal;
  }

  void _forwardImageToChat(
      {int? uid, int? gid, required File imageFile, String? targetName}) async {
    try {
      final title = AppLocalizations.of(context)!.forwardAsImage +
          ((targetName != null && targetName.isNotEmpty)
              ? " ${AppLocalizations.of(context)!.to} $targetName"
              : "");

      await showAppAlert(
          context: context,
          title: title,
          contentWidget: Image.file(imageFile),
          actions: [
            AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.of(context).pop(),
            ),
            AppAlertDialogAction(
              text: AppLocalizations.of(context)!.continueStr,
              action: () {
                SendService.singleton.sendMessage(
                  uuid(),
                  imageFile.path,
                  SendType.file,
                  gid: gid,
                  uid: uid,
                );
                Navigator.of(context).pop();
              },
            )
          ]);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void _share() async {
    Navigator.of(context).pop();
    try {
      Share.shareXFiles([XFile(widget.imageFile.path)]);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<List<RecentChatData>> _getRecentChats() async {
    List<RecentChatData> recentChatList = [];

    final channelList = await GroupInfoDao().getAllGroupList();
    if (channelList != null) {
      for (final channel in channelList) {
        final localMid =
            await ChatMsgDao().getLatestLocalMidInGroup(channel.gid);
        final latestMsgM = await ChatMsgDao().getMsgBylocalMid(localMid);
        recentChatList.add(RecentChatData(
            groupInfoM: channel,
            updatedAt: latestMsgM?.createdAt ?? channel.updatedAt));
      }
    }

    final dmList = await DmInfoDao().getDmList();
    if (dmList != null) {
      for (final dm in dmList) {
        final localMid = await ChatMsgDao().getLatestLocalMidInDm(dm.dmUid);
        final latestMsgM = await ChatMsgDao().getMsgBylocalMid(localMid);
        final userInfoM = await UserInfoDao().getUserByUid(dm.dmUid);
        if (userInfoM != null) {
          recentChatList.add(RecentChatData(
              userInfoM: userInfoM,
              updatedAt: latestMsgM?.createdAt ?? userInfoM.createdAt));
        }
      }
    }

    recentChatList.sort(((a, b) => b.updatedAt.compareTo(a.updatedAt)));

    return recentChatList;
  }
}

class RecentChatData {
  final UserInfoM? userInfoM;
  final GroupInfoM? groupInfoM;
  final int updatedAt;

  bool get isGroup => userInfoM == null && groupInfoM != null;
  String get title =>
      isGroup ? groupInfoM!.groupInfo.name : userInfoM!.userInfo.name;

  RecentChatData({this.userInfoM, this.groupInfoM, required this.updatedAt});
}
