import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/ui_models/ui_forward.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:vocechat_client/ui/widgets/sheet_app_bar.dart';

class ForwardSheet extends StatefulWidget {
  List<int>? midList;
  String? archiveId;

  ForwardSheet({this.midList, this.archiveId}) {
    assert((midList == null) ^ (archiveId == null));
  }

  @override
  State<ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends State<ForwardSheet> {
  final ValueNotifier<List<int>> uidNotifier = ValueNotifier([]);
  final ValueNotifier<List<int>> gidNotifier = ValueNotifier([]);
  late bool _isSending;

  @override
  void initState() {
    super.initState();
    _isSending = false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8))),
        child: SafeArea(
          child: Column(
            children: [
              SheetAppBar(
                  title: Text(
                    "Forward to ",
                    style: AppTextStyles.titleLarge(),
                  ),
                  leading: CupertinoButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.close)),
                  actions: [
                    _isSending
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CupertinoActivityIndicator(),
                          )
                        : CupertinoButton(
                            child: Text(
                              "Select",
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: AppColors.primary400),
                            ),
                            onPressed: () async {
                              setState(() {
                                _isSending = true;
                              });

                              try {
                                bool hasSent = false;
                                if (widget.midList != null) {
                                  hasSent = await App.app.chatService
                                      .sendForward(widget.midList!,
                                          uidNotifier.value, gidNotifier.value);
                                } else if (widget.archiveId != null) {
                                  hasSent = await App.app.chatService
                                      .sendArchiveForward(widget.archiveId!,
                                          uidNotifier.value, gidNotifier.value);
                                }

                                if (hasSent) {
                                  setState(() {
                                    _isSending = false;
                                    Navigator.of(context).pop();
                                  });
                                } else {
                                  App.logger.severe("Send failed");
                                  setState(() {
                                    _isSending = false;
                                    Navigator.of(context).pop();
                                  });
                                }
                              } catch (e) {
                                App.logger.severe(e);

                                setState(() {
                                  _isSending = false;
                                  Navigator.of(context).pop();
                                });
                              }
                            })
                  ]),
              SizedBox(
                height: 36,
                child: TabBar(
                    labelColor: AppColors.grey600,
                    indicatorColor: AppColors.grey600,
                    unselectedLabelColor: AppColors.grey300,
                    tabs: [
                      Text("Channels",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.grey600)),
                      Text("Contacts",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.grey600)),
                    ]),
              ),
              Expanded(
                child: TabBarView(
                  children: [_buildChannels(), _buildContact()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecents() {
    return FutureBuilder<List<UiForward>?>(
        future: getRecentList(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final recentList = snapshot.data!;
            return ListView.builder(
                itemCount: recentList.length,
                itemBuilder: (context, index) {
                  final uiForward = recentList[index];
                  return GestureDetector(
                    onTap: () {
                      if (uiForward.isGroup) {
                        final gid = uiForward.gid!;
                        onTapChannel(gid);
                      } else {
                        final uid = uiForward.uid!;
                        onTapUser(uid);
                      }
                      // setState(() {});
                    },
                    child: Row(
                      children: [
                        if (uiForward.isGroup)
                          _buildGroupSelect(uiForward.gid)
                        else
                          _buildUserSelect(uiForward.uid),
                        Expanded(
                          child: ListTile(
                            leading: getAvatar(uiForward),
                            title: Text(uiForward.title),
                          ),
                        ),
                      ],
                    ),
                  );
                });
          }
          return SizedBox.shrink();
        });
  }

  void onTapChannel(int gid) {
    if (gidNotifier.value.contains(gid)) {
      gidNotifier.value = List.from(gidNotifier.value)
        ..removeWhere((element) => element == gid);
    } else {
      gidNotifier.value = List.from(gidNotifier.value)..add(gid);
    }
    setState(() {});
  }

  void onTapUser(int uid) {
    if (uidNotifier.value.contains(uid)) {
      uidNotifier.value = List.from(uidNotifier.value)
        ..removeWhere((element) => element == uid);
    } else {
      uidNotifier.value = List.from(uidNotifier.value)..add(uid);
    }
    setState(() {});
  }

  Widget _buildGroupSelect(int? gid) {
    const double size = 40;

    return Container(
      height: size,
      width: size,
      child: Center(
        child: gidNotifier.value.contains(gid)
            ? Icon(AppIcons.select, color: Colors.cyan, size: 24)
            : SizedBox.shrink(),
      ),
    );
  }

  Widget _buildUserSelect(int? uid) {
    const double size = 40;

    return Container(
      height: size,
      width: size,
      child: Center(
        child: uidNotifier.value.contains(uid)
            ? Icon(Icons.check_box_outlined, color: Colors.cyan, size: 30)
            : Icon(Icons.check_box_outline_blank_rounded,
                color: Colors.cyan, size: 30),
      ),
    );
  }

  Widget _buildChannels() {
    return SafeArea(
      child: ListView(
        children: [
          FutureBuilder<List<GroupInfoM>?>(
              future: GroupInfoDao().getAllGroupList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final groupList = snapshot.data!;
                  return Column(
                    children: List<Widget>.generate(groupList.length, (index) {
                      final group = groupList[index];
                      final avatar = group.isPublic == 1
                          ? Icon(AppIcons.channel, size: 20)
                          : Icon(AppIcons.private_channel, size: 20);
                      return GestureDetector(
                        onTap: () {
                          onTapChannel(group.gid);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: avatar,
                                title: Text(
                                  group.groupInfo.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: AppColors.grey600),
                                ),
                              ),
                            ),
                            _buildGroupSelect(group.gid),
                          ],
                        ),
                      );
                    }),
                  );
                }
                return SizedBox.shrink();
              }),
        ],
      ),
    );
  }

  Widget _buildContact() {
    return FutureBuilder<List<UserInfoM>?>(
      future: UserInfoDao().getUserList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ContactList(
              userList: snapshot.data!,
              enableSelect: true,
              selectNotifier: uidNotifier,
              onTap: (userInfoM) {
                onTapUser(userInfoM.uid);
              });
        }
        return Center(
            child: CupertinoActivityIndicator(
          radius: 12,
        ));
      },
    );
  }

  Widget getAvatar(UiForward uiForward) {
    const double size = 40;
    if (uiForward.avatar == null) {
      if (uiForward.isGroup) {
        if (uiForward.isPublicChannel) {
          return Icon(AppIcons.channel, size: size);
        } else {
          return Icon(AppIcons.private_channel, size: size);
        }
      }
      return CircleAvatar(child: Text(uiForward.title.substring(0, 1)));
    } else {
      return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                  fit: BoxFit.fill, image: MemoryImage(uiForward.avatar!))));
    }
  }

  Future<List<UiForward>?> getRecentList() async {
    final List<GroupInfoM>? groups = await GroupInfoDao().getAllGroupList();
    final List<DmInfoM>? dms = await DmInfoDao().getDmList();

    List<UiForward> recents = [];
    if (groups != null) {
      for (var each in groups) {
        final uiForward = UiForward(
            title: each.groupInfo.name,
            gid: each.gid,
            time: each.updatedAt,
            isPublicChannel: each.isPublic == 1);
        recents.add(uiForward);
      }
    }

    if (dms != null) {
      for (var each in dms) {
        try {
          final userInfoM = (await UserInfoDao().getUserByUid(each.dmUid))!;
          final uiForward = UiForward(
              title: userInfoM.userInfo.name,
              uid: userInfoM.uid,
              avatar:
                  userInfoM.avatarBytes.isEmpty ? null : userInfoM.avatarBytes,
              time: each.updatedAt);
          recents.add(uiForward);
        } catch (e) {
          App.logger.severe(e);
          return null;
        }
      }
    }

    recents.sort((a, b) => b.time.compareTo(a.time));
    return recents;
  }

  Future<List<UiForward>?> getFullList() async {
    final List<GroupInfoM>? groups = await GroupInfoDao().getAllGroupList();
    final List<UserInfoM>? users = await UserInfoDao().getUserList();
    // users.sort(((a, b) => a.userInfo.name));

    List<UiForward> recents = [];
    if (groups != null) {
      for (var each in groups) {
        final uiForward = UiForward(
            title: each.groupInfo.name,
            gid: each.gid,
            time: 0,
            isPublicChannel: each.isPublic == 1);
        recents.add(uiForward);
      }
    }

    if (users != null) {
      for (var each in users) {
        try {
          final uiForward = UiForward(
              title: each.userInfo.name,
              uid: each.uid,
              avatar: each.avatarBytes.isEmpty ? null : each.avatarBytes,
              time: 0);
          recents.add(uiForward);
        } catch (e) {
          App.logger.severe(e);
          return null;
        }
      }
    }

    return recents;
  }
}
