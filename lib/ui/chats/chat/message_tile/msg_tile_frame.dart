import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';

import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class MsgTileFrame extends StatelessWidget {
  final String username;
  late final Color nameColor;

  final double? contentWidth;

  // final UserInfoM? userInfoM;

  /// Font size of name.
  final double nameSize;

  final File? avatarFile;
  final double avatarSize;

  final bool enableOnlineStatus;
  final ValueNotifier<bool>? onlineNotifier;
  final bool isFollowing;
  final int? uid;
  final int? timeStamp;
  final bool enableLeadingGap;
  final bool enableAvatarMention;
  final bool enableUserDetailPush;
  final GlobalKey<AppMentionsState>? mentionsKey;
  final Widget? child;

  MsgTileFrame(
      {Key? key,
      required this.username,
      Color? nameColor,
      this.contentWidth,
      this.nameSize = 14,
      required this.avatarFile,
      this.avatarSize = VoceAvatarSize.s36,
      this.enableOnlineStatus = false,
      this.onlineNotifier,
      this.isFollowing = false,
      this.uid,
      this.timeStamp,
      this.enableLeadingGap = false,
      this.enableAvatarMention = false,
      this.enableUserDetailPush = false,
      this.mentionsKey,
      this.child})
      : super(key: key) {
    if (nameColor != null) {
      this.nameColor = nameColor;
    } else {
      this.nameColor = AppColors.cyan500;
    }
    // assert(avatarBytes.isEmpty && username.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    String displayedName = "Deleted User";

    if (username.isNotEmpty) {
      displayedName = username;
    } else {
      if (uid != null) {
        displayedName = "User #$uid";
      }
    }
    return Container(
      constraints: isFollowing
          ? BoxConstraints(minHeight: 20)
          : BoxConstraints(minHeight: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
              onTap: () {
                if (enableUserDetailPush) {
                  _showUserDetail(context, uid);
                }
              },
              onLongPress: () {
                if (enableAvatarMention && uid != -1) {
                  mentionsKey?.currentState?.controller?.text += ' @$username ';
                  mentionsKey?.currentState?.controller?.selection =
                      TextSelection.fromPosition(TextPosition(
                          offset: mentionsKey
                                  ?.currentState?.controller?.text.length ??
                              0));
                }
              },
              child: _buildAvatar(displayedName)),
          SizedBox(width: 8),
          SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isFollowing)
                  SizedBox(
                    height: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            minSize: 12,
                            onPressed: enableUserDetailPush
                                ? () {
                                    if (enableUserDetailPush) {
                                      _showUserDetail(context, uid);
                                    }
                                  }
                                : null,
                            child: Text(displayedName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                strutStyle: StrutStyle(forceStrutHeight: true),
                                style: TextStyle(
                                    fontSize: nameSize,
                                    color: nameColor,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          DateTime.fromMillisecondsSinceEpoch(timeStamp!)
                              .toChatTime24StrEn(context),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navLink),
                        )
                      ],
                    ),
                  ),
                if (child != null) child!,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String displayedName) {
    if (avatarFile != null) {
      return VoceUserAvatar.file(
          file: avatarFile!,
          size: avatarSize,
          uid: uid ?? -1,
          name: displayedName,
          enableOnlineStatus: false);
    } else if (displayedName.isNotEmpty) {
      return VoceUserAvatar.name(
          name: displayedName, size: avatarSize, enableOnlineStatus: false);
    } else if (uid == null || uid == -1) {
      return VoceUserAvatar.deleted(size: avatarSize);
    } else {
      return VoceUserAvatar.file(
          file: avatarFile!,
          size: avatarSize,
          uid: uid ?? -1,
          name: displayedName,
          enableOnlineStatus: false);
    }
  }

  void _showUserDetail(BuildContext context, int? uid) async {
    if (uid == null || uid < 1) {
      return;
    }
    final userInfoM = await UserInfoDao().getUserByUid(uid);
    if (userInfoM != null) {
      Navigator.pushNamed(context, ContactDetailPage.route,
          arguments: userInfoM);
    }
  }
}
