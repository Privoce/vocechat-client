import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/agora/av_action_sheet.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class AvChatPage extends StatefulWidget {
  final ValueNotifier<GroupInfoM>? groupInfoNotifier;
  final ValueNotifier<UserInfoM>? userInfoNotifier;

  const AvChatPage.channel(
      {super.key, required ValueNotifier<GroupInfoM> this.groupInfoNotifier})
      : userInfoNotifier = null;

  const AvChatPage.dm(
      {super.key, required ValueNotifier<UserInfoM> this.userInfoNotifier})
      : groupInfoNotifier = null;

  @override
  State<AvChatPage> createState() => _AvChatPageState();
}

class _AvChatPageState extends State<AvChatPage> {
  bool get _isGroup => widget.groupInfoNotifier != null;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [_buildBody(context), AvActionSheet(items: [])],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(children: [_buildBar(context)]),
    );
  }

  Widget _buildBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        roundButton(Icons.arrow_back_ios_new, 24, onPressed: () {
          Navigator.of(context).pop();
        }),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: _buildTitleInfo(),
          ),
        ),
        roundButton(AppIcons.people, 24)
      ]),
    );
  }

  Widget _buildTitleInfo() {
    Widget avatar;
    Widget title;

    if (_isGroup) {
      avatar = VoceChannelAvatar.channel(
          groupInfoM: widget.groupInfoNotifier!.value,
          size: VoceAvatarSize.s24);
      title = ValueListenableBuilder<GroupInfoM>(
        valueListenable: widget.groupInfoNotifier!,
        builder: (context, groupInfoM, child) {
          return Text(groupInfoM.groupInfo.name,
              style: AppTextStyles.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis);
        },
      );
    } else {
      avatar = VoceUserAvatar.user(
          userInfoM: widget.userInfoNotifier!.value, size: VoceAvatarSize.s24);
      title = ValueListenableBuilder<UserInfoM>(
        valueListenable: widget.userInfoNotifier!,
        builder: (context, userInfoM, child) {
          return Text(userInfoM.userInfo.name,
              style: AppTextStyles.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis);
        },
      );
    }
    return Row(
      children: [avatar, SizedBox(width: 8), title],
    );
  }

  Widget roundButton(IconData icon, double size, {VoidCallback? onPressed}) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(size)),
            child: Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, size: size, color: Colors.white),
            ))));
  }
}