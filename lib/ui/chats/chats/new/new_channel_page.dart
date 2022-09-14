import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/models/group/group_create_request.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/new/new_private_channel_select_page.dart';
import 'package:vocechat_client/ui/widgets/app_textfield.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/channel_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NewChannelPage extends StatefulWidget {
  final bool enablePublic;

  NewChannelPage({Key? key, required this.enablePublic}) : super(key: key);

  @override
  State<NewChannelPage> createState() => _NewChannelPageState();
}

class _NewChannelPageState extends State<NewChannelPage> {
  late bool isPrivate;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _desController = TextEditingController();

  final ValueNotifier<List<int>> selectedNotifier =
      ValueNotifier([App.app.userDb!.uid]);

  @override
  void initState() {
    super.initState();

    isPrivate = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          toolbarHeight: barHeight,
          elevation: 0,
          backgroundColor: AppColors.coolGrey200,
          title: Text(AppLocalizations.of(context)!.newChannelPageTitle,
              style: AppTextStyles.titleLarge(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
          leading: CupertinoButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Icon(Icons.close, color: AppColors.grey97)),
          actions: [
            isPrivate
                ? CupertinoButton(
                    onPressed: () async {
                      final userList = await UserInfoDao().getUserList();

                      final groupInfoM = await Navigator.of(context)
                          .push<GroupInfoM?>(
                              MaterialPageRoute(builder: ((context) {
                        return NewPrivateChannelSelectPage(userList!,
                            selectedNotifier, _nameController, _desController);
                      })));
                      if (groupInfoM != null) {
                        Navigator.of(context).pop(groupInfoM);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.next,
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            color: AppColors.primary400)))
                : CupertinoButton(
                    onPressed: () {
                      createChannel();
                    },
                    child: Text(AppLocalizations.of(context)!.done,
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            color: AppColors.primary400))),
          ],
        ),
        body: SafeArea(
            child: ListView(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            SizedBox(height: 16),
            _buildTextFields(),
            SizedBox(height: 10),
            _buildSwitch(),
          ],
        )));
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: ChannelAvatar(
            isPublic: !isPrivate,
            avatarSize: AvatarSize.s60,
            avatarBytes: Uint8List(0)),
      ),
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        AppTextField(
          maxLines: 1,
          textInputAction: TextInputAction.next,
          header: AppLocalizations.of(context)!.newChannelPageName,
          hintText: isPrivate ? "New Private Channel" : "New Public Channel",
          controller: _nameController,
        ),
        SizedBox(height: 8),
        AppTextField(
          maxLines: 3,
          textInputAction: TextInputAction.done,
          header: AppLocalizations.of(context)!.newChannelPageDes,
          controller: _desController,
        )
      ],
    );
  }

  Widget _buildSwitch() {
    String text = isPrivate
        ? AppLocalizations.of(context)!.newChannelPagePrivateEnableDes
        : AppLocalizations.of(context)!.newChannelPagePrivateDisableDes;
    text += " " + AppLocalizations.of(context)!.newChannelPagePrivateDes;

    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BannerTile(
          onTap: () {},
          title: AppLocalizations.of(context)!.newChannelPagePrivateChannel,
          keepArrow: false,
          trailing: CupertinoSwitch(
              value: isPrivate,
              onChanged: (value) {
                setState(() {
                  isPrivate = value;
                });
              }),
        ),
        Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              text,
              style: TextStyle(
                  color: AppColors.grey400,
                  fontWeight: FontWeight.w400,
                  fontSize: 13),
            )),
      ],
    );

    if (widget.enablePublic) {
      return child;
    } else {
      setState(() {
        isPrivate = true;
      });
      // return Opacity(opacity: 0.5, child: AbsorbPointer(child: child));
      return SizedBox.shrink();
    }
  }

  void createChannel() async {
    try {
      String name = _nameController.text.trim();
      if (name.isEmpty) {
        name = "New Public Channel";
      }

      const String description = "";

      final req = GroupCreateRequest(
          name: name,
          description: description,
          isPublic: !isPrivate,
          members: null);

      App.logger.info(req.toJson());

      final gid = await createGroup(req);
      if (gid == -1) {
        App.logger.severe("Group Creation Failed");
      } else {
        GroupInfo groupInfo = GroupInfo(
            gid, App.app.userDb!.uid, name, description, [], true, 0, []);
        GroupInfoM groupInfoM = GroupInfoM.item(gid, "", jsonEncode(groupInfo),
            Uint8List(0), "", 1, 1, DateTime.now().millisecondsSinceEpoch);
        await GroupInfoDao()
            .addOrNotUpdate(groupInfoM)
            .then((value) => Navigator.pop(context, value));
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<int> createGroup(GroupCreateRequest req) async {
    final groupApi = GroupApi(App.app.chatServerM.fullUrl);
    final res = await groupApi.create(req);
    if (res.statusCode == 200 && res.data != null) {
      final gid = res.data!;
      return gid;
    }
    return -1;
  }
}
