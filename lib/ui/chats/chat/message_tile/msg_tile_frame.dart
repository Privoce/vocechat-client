import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';

class MsgTileFrame extends StatelessWidget {
  final String username;
  late final Color nameColor;

  /// Font size of name.
  final double nameSize;

  final Uint8List avatarBytes;
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
      this.nameSize = 14,
      required this.avatarBytes,
      this.avatarSize = AvatarSize.s36,
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
              if (enableAvatarMention) {
                mentionsKey?.currentState?.controller?.text = ' @$username ';
              }
            },
            child: uid == -1
                ? UserAvatar.deletedUser(avatarSize: avatarSize)
                : UserAvatar(
                    avatarSize: avatarSize,
                    isSelf: App.app.isSelf(uid),
                    name: username,
                    uid: uid ?? -1,
                    avatarBytes: avatarBytes,
                    enableOnlineStatus: enableOnlineStatus,
                  ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFollowing)
                SizedBox(
                  height: 20,
                  child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(children: [
                        TextSpan(
                            text: displayedName + "  ",
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (enableUserDetailPush) {
                                  _showUserDetail(context, uid);
                                }
                              },
                            style: TextStyle(
                                fontSize: nameSize,
                                color: nameColor,
                                fontWeight: FontWeight.w500)),
                        TextSpan(
                          text: DateTime.fromMillisecondsSinceEpoch(timeStamp!)
                              .toChatTime24StrEn(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navLink),
                        )
                      ])),
                ),
              if (child != null) child!,
            ],
          ),
        ],
      ),
    );
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
