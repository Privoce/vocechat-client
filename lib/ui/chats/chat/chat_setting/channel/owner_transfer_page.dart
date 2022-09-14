import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/models/group/group_update_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';

class OwnerTransferPage extends StatefulWidget {
  final GroupInfoM groupInfoM;

  OwnerTransferPage({required this.groupInfoM});

  @override
  State<OwnerTransferPage> createState() => _OwnerTransferPageState();
}

class _OwnerTransferPageState extends State<OwnerTransferPage> {
  final ValueNotifier<bool> _busyNotifier = ValueNotifier(false);
  final ValueNotifier<List<int>> _selectNotifier = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(242, 244, 247, 1),
        appBar: AppBar(
          leading: CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
          title: Text("Transfer Owner", style: AppTextStyles.titleLarge()),
          backgroundColor: AppColors.barBg,
          elevation: 0,
          actions: [
            ValueListenableBuilder<bool>(
                valueListenable: _busyNotifier,
                builder: (context, isBusy, _) {
                  if (isBusy) {
                    return Row(
                      children: [
                        CupertinoActivityIndicator(),
                        CupertinoButton(
                            onPressed: () {},
                            child: Text("Done",
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 17,
                                    color: AppColors.grey200)))
                      ],
                    );
                  }
                  return CupertinoButton(
                      onPressed: () async {
                        _busyNotifier.value = true;
                        if (await _transferOwner()) {
                          _busyNotifier.value = false;
                          Navigator.of(context).pop();
                          return;
                        }
                        Navigator.of(context).pop();
                        _busyNotifier.value = false;
                      },
                      child: Text("Done",
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: AppColors.primary400)));
                })
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<UserInfoM>?>(
              future: _getUsers(),
              builder: ((context, snapshot) {
                if (snapshot.hasData) {
                  return ContactList(
                    userList: snapshot.data!,
                    ownerUid: widget.groupInfoM.groupInfo.owner,
                    onTap: (userInfoM) {
                      if (_selectNotifier.value.contains(userInfoM.uid)) {
                        _selectNotifier.value = [];
                      } else {
                        _selectNotifier.value = [userInfoM.uid];
                      }
                    },
                    preSelectUidList: [widget.groupInfoM.groupInfo.owner ?? -1],
                    enablePreSelectAction: false,
                    enableSelect: true,
                    enableUserUpdate: false,
                    selectNotifier: _selectNotifier,
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CupertinoActivityIndicator());
                } else {
                  return SizedBox.shrink();
                }
              })),
        ));
  }

  Future<List<UserInfoM>?> _getUsers() async {
    final GroupInfoM? groupInfoM =
        await GroupInfoDao().getGroupByGid(widget.groupInfoM.gid);
    if (groupInfoM == null) {
      return null;
    }

    return GroupInfoDao().getUserListByGid(widget.groupInfoM.gid,
        groupInfoM.isPublic == 1, groupInfoM.groupInfo.members ?? []);
  }

  Future<bool> _transferOwner() async {
    if (_selectNotifier.value.isEmpty || _selectNotifier.value.length != 1) {
      return false;
    }

    final req = GroupUpdateRequest(owner: _selectNotifier.value.first);
    try {
      final groupApi = GroupApi(App.app.chatServerM.fullUrl);
      final res = await groupApi.updateGroup(widget.groupInfoM.gid, req);
      if (res.statusCode == 200) {
        // success
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
