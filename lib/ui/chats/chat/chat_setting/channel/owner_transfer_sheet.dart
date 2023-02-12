import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/models/group/group_update_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_page.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:vocechat_client/ui/widgets/sheet_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OwnerTransferSheet extends StatefulWidget {
  final GroupInfoM groupInfoM;

  OwnerTransferSheet({required this.groupInfoM});

  @override
  State<OwnerTransferSheet> createState() => _OwnerTransferSheetState();
}

class _OwnerTransferSheetState extends State<OwnerTransferSheet> {
  final ValueNotifier<bool> _busyNotifier = ValueNotifier(false);
  final ValueNotifier<List<int>> _selectNotifier = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        SheetAppBar(
          title: Text(AppLocalizations.of(context)!.transferOwnership,
              style: AppTextStyles.titleLarge),
          leading: CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.close, color: AppColors.grey97)),
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
                            child: Text(AppLocalizations.of(context)!.done,
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
                        if (await _transferOwner() && await _leave()) {
                          _busyNotifier.value = false;
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          return;
                        }
                        Navigator.of(context).pop();
                        _busyNotifier.value = false;
                      },
                      child: Text(AppLocalizations.of(context)!.done,
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: AppColors.primary400)));
                })
          ],
        ),
        Expanded(
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
        ),
      ],
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
      final groupApi = GroupApi();
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

  Future<bool> _leave() async {
    try {
      final groupApi = GroupApi();
      final res = await groupApi.leaveGroup(widget.groupInfoM.gid);
      if (res.statusCode == 200) {
        await FileHandler.singleton
            .deleteChatDirectory(getChatId(gid: widget.groupInfoM.gid)!);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
