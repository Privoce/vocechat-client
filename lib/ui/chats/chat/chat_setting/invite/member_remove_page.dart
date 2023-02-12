import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/sheet_app_bar.dart';

class MemberRemovePage extends StatefulWidget {
  final ValueNotifier<GroupInfoM> groupInfoMNotifier;

  MemberRemovePage(this.groupInfoMNotifier);

  @override
  State<MemberRemovePage> createState() => _MemberRemovePageState();
}

class _MemberRemovePageState extends State<MemberRemovePage>
    with TickerProviderStateMixin {
  late final Future<List<UserInfoM>?> membersFuture;

  final ValueNotifier<List<int>> selectNotifier = ValueNotifier([]);

  late bool _isSending;

  @override
  void initState() {
    super.initState();
    membersFuture = prepareUserList();

    _isSending = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        SheetAppBar(
          title: Text(
            AppLocalizations.of(context)!.memberRemovePageTitle,
            style: AppTextStyles.titleLarge,
          ),
          leading: CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.close, color: AppColors.grey97)),
          actions: [_buildSendBtn()],
        ),
        Flexible(
          child: FutureBuilder<List<UserInfoM>?>(
              future: membersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ContactList(
                    userList: snapshot.data!,
                    ownerUid: widget.groupInfoMNotifier.value.groupInfo.owner,
                    onTap: (user) {
                      if (selectNotifier.value.contains(user.uid)) {
                        selectNotifier.value = List<int>.from(
                            selectNotifier.value..remove(user.uid));
                      } else {
                        selectNotifier.value =
                            List<int>.from(selectNotifier.value..add(user.uid));
                      }
                    },
                    preSelectUidList: {
                      App.app.userDb!.uid,
                      widget.groupInfoMNotifier.value.groupInfo.owner!
                    }.toList(),
                    selectNotifier: selectNotifier,
                    enableSelect: true,
                    enablePreSelectAction: false,
                  );
                }
                return SizedBox.shrink();
              }),
        )
      ],
    ));
    // return Container(
    //   decoration: BoxDecoration(
    //       color: Colors.white,
    //       borderRadius: BorderRadius.only(
    //           topLeft: Radius.circular(8), topRight: Radius.circular(8))),
    //   child: Scaffold(
    //     appBar: AppBar(
    //       toolbarHeight: 70,
    //       elevation: 0,
    //       backgroundColor: Colors.white,
    //       title: Text(
    //         AppLocalizations.of(context)!.memberRemovePageTitle,
    //         style: AppTextStyles.titleLarge,
    //       ),
    //       leading: CupertinoButton(
    //           onPressed: () {
    //             Navigator.pop(context);
    //           },
    //           child: Icon(Icons.close, color: AppColors.grey97)),
    //       actions: [_buildSendBtn()],
    //     ),
    //     body: SafeArea(
    //         child: FutureBuilder<List<UserInfoM>?>(
    //             future: membersFuture,
    //             builder: (context, snapshot) {
    //               if (snapshot.hasData) {
    //                 return ContactList(
    //                   userList: snapshot.data!,
    //                   ownerUid: widget.groupInfoMNotifier.value.groupInfo.owner,
    //                   onTap: (user) {
    //                     if (selectNotifier.value.contains(user.uid)) {
    //                       selectNotifier.value = List<int>.from(
    //                           selectNotifier.value..remove(user.uid));
    //                     } else {
    //                       selectNotifier.value = List<int>.from(
    //                           selectNotifier.value..add(user.uid));
    //                     }
    //                   },
    //                   preSelectUidList: {
    //                     App.app.userDb!.uid,
    //                     widget.groupInfoMNotifier.value.groupInfo.owner!
    //                   }.toList(),
    //                   selectNotifier: selectNotifier,
    //                   enableSelect: true,
    //                   enablePreSelectAction: false,
    //                 );
    //               }
    //               return SizedBox.shrink();
    //             })),
    //   ),
    // );
  }

  Future<List<UserInfoM>?> prepareUserList() async {
    return GroupInfoDao().getUserListByGid(
        widget.groupInfoMNotifier.value.gid,
        widget.groupInfoMNotifier.value.isPublic == 1,
        widget.groupInfoMNotifier.value.groupInfo.members ?? [],
        batchSize: 0);
  }

  Widget _buildSendBtn() {
    if (widget.groupInfoMNotifier.value.isPublic == 1) {
      return SizedBox.shrink();
    }
    return ValueListenableBuilder<List<int>>(
        valueListenable: selectNotifier,
        builder: (context, uidList, _) {
          final removeCount = selectNotifier.value.length;

          final countText = removeCount > 0 ? "($removeCount)" : "";

          final btnText =
              AppLocalizations.of(context)!.memberRemovePageRemove + countText;
          return CupertinoButton(
              padding: EdgeInsets.all(4),
              onPressed: () async {
                setState(() {
                  _isSending = true;
                });

                try {
                  final removes = selectNotifier.value;
                  final groupApi = GroupApi();
                  final hasSent = await groupApi.removeMembers(
                      widget.groupInfoMNotifier.value.gid, removes.toList());
                  if (hasSent.statusCode == 200) {
                    setState(() {
                      _isSending = false;
                      Navigator.of(context).pop();
                    });
                  }
                } catch (e) {
                  App.logger.severe(e);

                  setState(() {
                    _isSending = false;
                  });
                }
              },
              child: Text(
                btnText,
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: AppColors.primary400),
              ));
        });
  }
}
