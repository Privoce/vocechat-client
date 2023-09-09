import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/models/group/group_create_request.dart';
import 'package:vocechat_client/api/models/group/group_create_response.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';

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
                          color: AppColors.primaryBlue)))
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
      body: ContactList(
          initUserList: widget.userList,
          selectNotifier: widget.selectedNotifier,
          onTap: (userInfoM) {
            if (widget.selectedNotifier.value.contains(userInfoM.uid)) {
              widget.selectedNotifier.value =
                  List.from(widget.selectedNotifier.value)
                    ..remove(userInfoM.uid);
            } else {
              widget.selectedNotifier.value =
                  List.from(widget.selectedNotifier.value)..add(userInfoM.uid);
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
          enableUpdate: true),
    );
  }

  void createChannel() async {
    try {
      String name = widget.nameController.text.trim();
      if (name.isEmpty) {
        name = AppLocalizations.of(context)!.newPrivateChannel;
      }

      String description = widget.desController.text.trim();
      List<int>? members = widget.selectedNotifier.value;

      if (members.length < 2) {
        App.logger.severe("Member count not enough: ${members.length}");
        return;
      }

      final req = GroupCreateRequest(
          name: name,
          description: description,
          isPublic: false,
          members: members);

      final serverVersionRes = await AdminSystemApi().getServerVersion();
      if (serverVersionRes.statusCode == 200) {
        final serverVersion = serverVersionRes.data!;

        if (isVersionNumberGreaterThan("0.3.3", serverVersion)) {
          await _createGroupBfe033(req);
        } else {
          await _createGroupAft033(req);
        }
      } else {
        return;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return;
  }

  bool isVersionNumberGreaterThan(String version1, String version2) {
    final version1List = version1.split(".");
    final version2List = version2.split(".");

    for (int i = 0; i < version1List.length; i++) {
      if (int.parse(version1List[i]) > int.parse(version2List[i])) {
        return true;
      }
    }
    return false;
  }

  Future<int?> createGroupBfe033(GroupCreateRequest req) async {
    final groupApi = GroupApi();
    final res = await groupApi.createBfe033(req);
    if (res.statusCode == 200 && res.data != null) {
      return res.data!;
    }
    return null;
  }

  Future<GroupCreateResponse?> createGroupAft033(GroupCreateRequest req) async {
    final groupApi = GroupApi();
    final res = await groupApi.createAft033(req);
    if (res.statusCode == 200 && res.data != null) {
      return res.data!;
    }
    return null;
  }

  Future<void> _createGroupBfe033(GroupCreateRequest req) async {
    final gid = await createGroupBfe033(req);
    if (gid == null || gid == -1) {
      App.logger.severe("Group Creation (before 0.3.4) Failed");
    } else {
      GroupInfo groupInfo = GroupInfo(gid, App.app.userDb!.uid, req.name,
          req.description, req.members, false, 0, []);
      GroupInfoM groupInfoM = GroupInfoM.item(
          gid,
          "",
          jsonEncode(groupInfo),
          // Uint8List(0),
          "",
          0,
          1,
          DateTime.now().millisecondsSinceEpoch);

      try {
        await GroupInfoDao()
            .addOrNotUpdate(groupInfoM)
            .then((value) => Navigator.pop(context, value));
      } catch (e) {
        App.logger.severe(e);
        Navigator.pop(context, groupInfoM);
      }
    }
  }

  Future<void> _createGroupAft033(GroupCreateRequest req) async {
    final groupCreateResponse = await createGroupAft033(req);
    if (groupCreateResponse == null || groupCreateResponse.gid == -1) {
      App.logger.severe("Group Creation (after 0.3.4) Failed");
    } else {
      GroupInfo groupInfo = GroupInfo(
          groupCreateResponse.gid,
          App.app.userDb!.uid,
          req.name,
          req.description,
          req.members,
          false,
          0, []);
      GroupInfoM groupInfoM = GroupInfoM.item(
          groupCreateResponse.gid,
          "",
          jsonEncode(groupInfo),
          // Uint8List(0),
          "",
          0,
          1,
          groupCreateResponse.createdAt);

      try {
        await GroupInfoDao()
            .addOrNotUpdate(groupInfoM)
            .then((value) => Navigator.pop(context, value));
      } catch (e) {
        App.logger.severe(e);
        Navigator.pop(context, groupInfoM);
      }
    }
  }
}
