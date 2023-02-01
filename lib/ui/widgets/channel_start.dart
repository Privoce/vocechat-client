import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/channel_info_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/channel/channel_settings_page.dart';

class ChannelStart extends StatelessWidget {
  final ValueNotifier<GroupInfoM> groupInfoNotifier;

  late final String _title;

  ChannelStart(this.groupInfoNotifier) {
    _title = groupInfoNotifier.value.groupInfo.name;
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
    bool isOwner =
        App.app.userDb?.uid == groupInfoNotifier.value.groupInfo.owner;

    return Container(
      // height: 100,
      width: double.maxFinite,
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(children: [
            TextSpan(text: "Welcome to ", style: AppTextStyles.titleLarge),
            TextSpan(text: "#$_title", style: AppTextStyles.titleLarge)
          ])),
          SizedBox(height: 8),
          Text("This is the start of the #$_title channel.",
              style: AppTextStyles.snippet),
          SizedBox(height: 10),
          if (isOwner || isAdmin)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChannelInfoPage(groupInfoNotifier)
                    // ChannelSettingsPage(groupInfoNotifier: groupInfoNotifier),
                    ));
              },
              child: Row(
                children: const [
                  Icon(AppIcons.edit, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Edit Channel",
                    style: TextStyle(fontSize: 16),
                  )
                ],
              ),
            ),
          Divider(color: AppColors.grey400),
        ],
      ),
    );
  }
}
