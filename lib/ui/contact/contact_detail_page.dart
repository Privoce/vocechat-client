import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/chat_page.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/widgets/app_banner_button.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactDetailPage extends StatefulWidget {
  static const route = "/contacts/detail";

  ContactDetailPage();

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late bool _enableBlock;

  @override
  void initState() {
    super.initState();
    _enableBlock = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoM = ModalRoute.of(context)!.settings.arguments as UserInfoM;

    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: _buildBar(context),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(userInfoM),
              _buildSettings(userInfoM.uid)
            ],
          ),
        )));
  }

  AppBar _buildBar(BuildContext context) {
    return AppBar(
      toolbarHeight: barHeight,
      elevation: 0,
      backgroundColor: AppColors.barBg,
      leading: CupertinoButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
    );
  }

  Widget _buildUserInfo(UserInfoM userInfoM) {
    final userInfo = userInfoM.userInfo;
    return AvatarInfoTile(
      avatar: UserAvatar(
          avatarSize: AvatarSize.s84,
          uid: userInfoM.uid,
          name: userInfo.name,
          enableOnlineStatus: true,
          avatarBytes: userInfoM.avatarBytes),
      title: userInfo.name,
      subtitle: userInfo.email,
    );
  }

  Widget _buildSettings(int uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // BannerTile(onTap: () {}, title: "Mute"),
          // BannerTile(onTap: () {}, title: "Change Nickname"),
          // BannerTile(onTap: () {}, title: "Share Contact"),
          // SizedBox(height: 8),
          // BannerTile(
          //   onTap: () {},
          //   title: "Block",
          //   keepArrow: false,
          //   trailing: CupertinoSwitch(
          //       value: _enableBlock,
          //       onChanged: (value) {
          //         setState(() {
          //           _enableBlock = value;
          //         });
          //       }),
          // ),
          AppBannerButton(
              title: AppLocalizations.of(context)!.contactDetailPageMessage,
              textColor: Colors.blue.shade800,
              onTap: () {
                onTapDm(uid, context);
              }),
          // SizedBox(height: 8),
          // AppBannerButton(
          //     title: AppLocalizations.of(context)!.contactDetailPageRemove,
          //     textColor: AppColors.systemRed,
          //     onTap: () {
          //       onTapDm(uid, context);
          //     })
        ],
      ),
    );
  }

  void onTapDm(int dmUid, BuildContext context) async {
    final userInfoM = (await UserInfoDao().getUserByUid(dmUid))!;

    final hintText = AppLocalizations.of(context)!.chatTextFieldHint +
        " @${userInfoM.userInfo.name}";
    final draft = userInfoM.properties.draft;
    final msgCount = await ChatMsgDao().getChatMsgCount(uid: dmUid);
    GlobalKey<AppMentionsState> mentionsKey = GlobalKey<AppMentionsState>();
    int unreadCount = await ChatMsgDao().getDmUnreadCount(dmUid);
    Navigator.push(
        context,
        MaterialPageRoute<String?>(
          builder: (context) => ChatPage(
              mentionsKey: mentionsKey,
              title: userInfoM.userInfo.name,
              msgCount: msgCount,
              hintText: hintText,
              draft: draft,
              userInfoNotifier: ValueNotifier(userInfoM),
              unreadCount: unreadCount),
        )).then((value) {
      final draft = mentionsKey.currentState?.controller?.text.trim();
      UserInfoDao()
          .updateProperties(userInfoM.uid, draft: draft)
          .then((value) async {
        if (value != null) {
          if ((await DmInfoDao().getDmInfo(value.uid)) != null) {
            App.app.chatService.fireUser(value, EventActions.update);
          } else {
            App.app.chatService.fireUser(value, EventActions.create);
          }
        }
      });
    });
  }
}
