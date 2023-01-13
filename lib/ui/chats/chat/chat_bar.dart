import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/channel_settings_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/dm/dm_settings_page.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';

class ChatBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueNotifier<GroupInfoM>? groupInfoNotifier;
  final ValueNotifier<int>? unreadCount;
  final ValueNotifier<UserInfoM>? userInfoNotifier;

  final VoidCallback onPop;

  late final bool _isGroup;

  ChatBar(
      {Key? key,
      required this.onPop,
      this.groupInfoNotifier,
      required this.unreadCount,
      this.userInfoNotifier})
      : super(key: key) {
    assert((groupInfoNotifier == null) ^ (userInfoNotifier == null));
    if (groupInfoNotifier != null) {
      _isGroup = true;
    } else if (userInfoNotifier != null) {
      _isGroup = false;
    }
  }

  @override
  State<ChatBar> createState() => _ChatBarState();

  @override
  Size get preferredSize => Size(double.maxFinite, barHeight);
}

class _ChatBarState extends State<ChatBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        titleSpacing: 0,
        leadingWidth: 74,
        leading: CupertinoButton(
            onPressed: () {
              widget.onPop();
            },
            child: SizedBox(
              width: 74,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new, color: AppColors.grey97),
                  if (widget.unreadCount != null)
                    Flexible(
                      child: ValueListenableBuilder<int>(
                          valueListenable: widget.unreadCount!,
                          builder: (context, unreadCount, _) {
                            if (unreadCount < 1) {
                              return SizedBox.shrink();
                            }
                            String text = unreadCount.toString();
                            if (unreadCount > 99) {
                              text = "99+";
                            }
                            return Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.grey500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17),
                            );
                          }),
                    )
                ],
              ),
            )),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            if (widget._isGroup) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelSettingsPage(
                        groupInfoNotifier: widget.groupInfoNotifier!),
                  ));
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DmSettingsPage(
                        userInfoNotifier: widget.userInfoNotifier!),
                  ));
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget._isGroup)
                ChannelAvatar(
                  avatarSize: AvatarSize.s36,
                  avatarBytes: widget.groupInfoNotifier!.value.avatar,
                  name: widget.groupInfoNotifier?.value.groupInfo.name ?? "",
                )
              else
                UserAvatar(
                    avatarSize: AvatarSize.s36,
                    uid: widget.userInfoNotifier!.value.uid,
                    name: widget.userInfoNotifier!.value.userInfo.name,
                    avatarBytes: widget.userInfoNotifier!.value.avatarBytes),
              SizedBox(width: 10),
              Expanded(
                child: _buildTitles(),
              ),
            ],
          ),
        ),
        actions: widget._isGroup
            ? _buildChannelActions(context)
            : _buildDmActions(context));
  }

  Widget _buildTitles() {
    if (widget._isGroup) {
      return ValueListenableBuilder<GroupInfoM>(
          valueListenable: widget.groupInfoNotifier!,
          builder: (context, groupInfoM, _) {
            final groupInfo = groupInfoM.groupInfo;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        groupInfo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                    if (widget._isGroup && groupInfoM.isPublic != 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.lock,
                            size: 16, color: AppColors.grey500),
                      ),
                  ],
                ),
                if (groupInfo.description != null &&
                    groupInfo.description!.isNotEmpty)
                  Text(
                    groupInfo.description!,
                    style: TextStyle(
                        color: AppColors.grey500,
                        fontSize: 13,
                        fontWeight: FontWeight.w300),
                  )
              ],
            );
          });
    } else {
      return ValueListenableBuilder<UserInfoM>(
          valueListenable: widget.userInfoNotifier!,
          builder: (context, userInfoM, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userInfoM.userInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge,
                ),
              ],
            );
          });
    }
  }

  List<Widget> _buildChannelActions(BuildContext context) {
    return [
      CupertinoButton(
          onPressed: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChannelSettingsPage(
                      groupInfoNotifier: widget.groupInfoNotifier!),
                ));
          },
          child: Icon(Icons.more_horiz, size: 20, color: AppColors.grey500))
    ];
  }

  List<Widget> _buildDmActions(BuildContext context) {
    return [
      CupertinoButton(
          onPressed: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DmSettingsPage(
                      userInfoNotifier: widget.userInfoNotifier!),
                ));
          },
          child: Icon(Icons.more_horiz, size: 20, color: AppColors.grey500))
    ];
  }
}
