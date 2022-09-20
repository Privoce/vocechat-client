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
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NewPrivateChannelSelectPage extends StatefulWidget {
  final List<UserInfoM> userList;
  final ValueNotifier<List<int>> selectedNotifier;

  final TextEditingController nameController;
  final TextEditingController desController;

  NewPrivateChannelSelectPage(this.userList, this.selectedNotifier,
      this.nameController, this.desController);

  @override
  State<NewPrivateChannelSelectPage> createState() =>
      _NewPrivateChannelSelectPageState();
}

class _NewPrivateChannelSelectPageState
    extends State<NewPrivateChannelSelectPage> {
  final List<int> preSelected = [App.app.userDb!.uid];

  late bool _enableDoneBtn;

  @override
  void initState() {
    super.initState();
    if (widget.selectedNotifier.value.length <= 1) {
      _enableDoneBtn = false;
    } else {
      _enableDoneBtn = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.coolGrey200,
        title: Text(AppLocalizations.of(context)!.newPrivateChannelSelectTitle,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Icon(Icons.arrow_back_ios_new_outlined,
                color: AppColors.grey97)),
        actions: [
          _enableDoneBtn
              ? CupertinoButton(
                  onPressed: () {
                    createChannel();
                  },
                  child: Text(AppLocalizations.of(context)!.done,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 17,
                          color: AppColors.primary400)))
              : AbsorbPointer(
                  child: CupertinoButton(
                      onPressed: () {},
                      child: Text(AppLocalizations.of(context)!.done,
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: AppColors.grey400))),
                ),
        ],
      ),
      body: SafeArea(
        child: ContactList(
            userList: widget.userList,
            selectNotifier: widget.selectedNotifier,
            onTap: (userInfoM) {
              if (widget.selectedNotifier.value.contains(userInfoM.uid)) {
                widget.selectedNotifier.value =
                    List.from(widget.selectedNotifier.value)
                      ..remove(userInfoM.uid);
              } else {
                widget.selectedNotifier.value =
                    List.from(widget.selectedNotifier.value)
                      ..add(userInfoM.uid);
              }

              if (widget.selectedNotifier.value.length > 1) {
                setState(() {
                  _enableDoneBtn = true;
                });
              } else {
                setState(() {
                  _enableDoneBtn = false;
                });
              }
            },
            enablePreSelectAction: false,
            preSelectUidList: preSelected,
            enableSelect: true,
            enableUserUpdate: true),
      ),
    );
  }

  void createChannel() async {
    try {
      String name = widget.nameController.text.trim();
      if (name.isEmpty) {
        name = "New Private Channel";
      }

      final String description = "";

      List<int>? members;

      members = widget.selectedNotifier.value;

      if (members.length < 2) {
        App.logger.severe("Member count not enough: ${members.length}");
        // TODO: add alert.
        return;
      }

      final req = GroupCreateRequest(
          name: name,
          description: description,
          isPublic: false,
          members: members);

      App.logger.info(req.toJson());

      final gid = await createGroup(req);
      if (gid == -1) {
        App.logger.severe("Group Creation Failed");
      } else {
        GroupInfo groupInfo = GroupInfo(
            gid, App.app.userDb!.uid, name, description, members, false, 0, []);
        GroupInfoM groupInfoM = GroupInfoM.item(gid, "", jsonEncode(groupInfo),
            Uint8List(0), "", 0, 1, DateTime.now().millisecondsSinceEpoch);

        try {
          await GroupInfoDao()
              .addOrNotUpdate(groupInfoM)
              .then((value) => Navigator.pop(context, value));
        } catch (e) {
          App.logger.severe(e);
          Navigator.pop(context, groupInfoM);
        }
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
