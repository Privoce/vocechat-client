import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/agora/av_action_sheet.dart';
import 'package:vocechat_client/ui/agora/round_button.dart';
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
      backgroundColor: Colors.white.withAlpha((255 * 0.3).round()),
      body: Stack(
        children: [
          _buildBody(context),
          AvActionSheet(btnItems: [
            // Size must be 24, in-button padding must be 16.
            RoundButton(icon: AppIcons.video, onPressed: () {}, size: 24),
            RoundButton(icon: AppIcons.mic, onPressed: () {}, size: 24),
            RoundButton(icon: AppIcons.speaker, onPressed: () {}, size: 24),
            RoundButton(
                icon: AppIcons.screen_share, onPressed: () {}, size: 24),
            RoundButton(
                icon: AppIcons.call_end,
                onPressed: () {},
                size: 24,
                backgroundColor: Colors.red),
          ])
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(children: [_buildBar(context)]),
    );
  }

  Widget _buildBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        RoundButton(
            icon: Icons.arrow_back_ios_new,
            paddingValue: 8,
            onPressed: () {
              Navigator.of(context).pop();
            }),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: _buildTitleInfo(),
          ),
        ),
        RoundButton(icon: AppIcons.people, paddingValue: 8)
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
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
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
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis);
        },
      );
    }
    return Row(
      children: [avatar, SizedBox(width: 8), title],
    );
  }
}
