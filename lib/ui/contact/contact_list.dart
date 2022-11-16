import 'package:flutter/material.dart';
import 'package:azlistview/azlistview.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/contact/contact_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';

class ContactList extends StatefulWidget {
  static const route = "/contacts";

  final List<UserInfoM> userList;
  final Function(UserInfoM userInfoM) onTap;
  final bool enableSelect;
  final double avatarSize;
  final ValueNotifier<List<int>>? selectNotifier;
  final List<int>? preSelectUidList;
  final bool enablePreSelectAction;
  final bool enableUserUpdate;
  final int? ownerUid;

  const ContactList(
      {required this.userList,
      required this.onTap,
      this.avatarSize = AvatarSize.s36,
      this.enableSelect = false,
      this.selectNotifier,
      this.preSelectUidList,
      this.enablePreSelectAction = true,
      this.enableUserUpdate = true,
      this.ownerUid,
      Key? key})
      : super(key: key);

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList>
    with AutomaticKeepAliveClientMixin {
  List<UserInfoM> _contactList = [];
  final Set<int> _uidSet = {};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _prepareContactList();

    if (widget.enableUserUpdate) {
      App.app.chatService.subscribeUsers(_onUser);
      App.app.chatService.subscribeReady(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.enableUserUpdate) {
      App.app.chatService.unsubscribeReady(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContactList();
  }

  Widget _buildContactList() {
    return AzListView(
      data: _contactList,
      itemCount: _contactList.length,
      itemBuilder: (context, index) {
        final user = _contactList[index];
        final isSelf = user.uid == App.app.userDb?.uid;
        final preSelected =
            widget.preSelectUidList?.contains(user.uid) ?? false;
        Widget? ownerMark;

        if (user.uid == widget.ownerUid) {
          ownerMark = Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: SvgPicture.asset("assets/images/owner.svg",
                  width: 14, height: 12, color: AppColors.violet100),
            ),
          );
        }

        String susTag = user.getSuspensionTag();
        return Column(
          children: [
            Offstage(
              offstage: user.isShowSuspension != true,
              child: _buildSusWidget(susTag),
            ),
            if (widget.selectNotifier != null)
              Opacity(
                opacity: preSelected ? 0.5 : 1,
                child: ValueListenableBuilder<List<int>>(
                    valueListenable: widget.selectNotifier!,
                    builder: (context, selectedList, _) {
                      return ContactTile(
                        user,
                        isSelf,
                        disabled: preSelected,
                        avatarSize: widget.avatarSize,
                        mark: ownerMark,
                        selected: selectedList.contains(user.uid),
                        onTap: () {
                          if (!widget.enablePreSelectAction && preSelected) {
                            return;
                          }
                          widget.onTap(user);
                        },
                      );
                    }),
              )
            else
              ContactTile(
                user,
                isSelf,
                disabled: preSelected,
                avatarSize: widget.avatarSize,
                mark: ownerMark,
                onTap: () {
                  if (!widget.enablePreSelectAction && preSelected) {
                    return;
                  }
                  widget.onTap(user);
                },
              )
          ],
        );
      },
      physics: BouncingScrollPhysics(),
      indexBarData: SuspensionUtil.getTagIndexList(_contactList),
      indexHintBuilder: (context, hint) {
        return Container(
          alignment: Alignment.center,
          width: 60.0,
          height: 60.0,
          decoration: BoxDecoration(
            color: Colors.cyan,
            shape: BoxShape.circle,
          ),
          child:
              Text(hint, style: TextStyle(color: Colors.white, fontSize: 30.0)),
        );
      },
      indexBarMargin: EdgeInsets.all(10),
      indexBarOptions: IndexBarOptions(
          hapticFeedback: HapticFeedback.mediumImpact,
          indexHintAlignment: Alignment.centerRight,
          needRebuild: true),
    );
  }

  // Widget _buildSelect(int uid) {
  //   const size = 40.0;
  //   return Container(
  //     height: size,
  //     width: size,
  //     margin: EdgeInsets.only(right: 40),
  //     child: ValueListenableBuilder<List<int>>(
  //       valueListenable: widget.selectNotifier!,
  //       builder: (context, uidList, _) {
  //         return Center(
  //           child: uidList.contains(uid)
  //               ? Icon(AppIcons.select, color: Colors.cyan, size: 24)
  //               : SizedBox.shrink(),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildSusWidget(String susTag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(color: AppColors.grey100),
      height: 20,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          Text(susTag),
        ],
      ),
    );
  }

  Future<void> _onUser(
      UserInfoM userInfoM, EventActions action, bool afterReady) async {
    switch (action) {
      case EventActions.create:
        if (!_uidSet.contains(userInfoM.uid)) {
          _uidSet.add(userInfoM.uid);
          _contactList.add(userInfoM);
        }

        break;
      case EventActions.update:
        if (!_uidSet.contains(userInfoM.uid)) {
          _uidSet.add(userInfoM.uid);
          App.logger
              .warning("User with uid: ${userInfoM.uid} not found in UI.");
        }

        _contactList.removeWhere((element) => element.uid == userInfoM.uid);
        _contactList.add(userInfoM);

        break;
      case EventActions.delete:
        if (_uidSet.contains(userInfoM.uid)) {
          _uidSet.remove(userInfoM.uid);
          _contactList.removeWhere((element) => element.uid == userInfoM.uid);
        } else {
          App.logger.severe("User with uid: ${userInfoM.uid} not found in UI.");
        }
        break;
      default:
        break;
    }
    SuspensionUtil.sortListBySuspensionTag(_contactList);
    SuspensionUtil.setShowSuspensionStatus(_contactList);
    // setState(() {});
  }

  void _prepareContactList() async {
    try {
      _contactList = widget.userList;
      _uidSet.addAll(_contactList.map((e) => e.uid));

      // A-Z sort.
      SuspensionUtil.sortListBySuspensionTag(_contactList);

      // show sus tag.
      SuspensionUtil.setShowSuspensionStatus(_contactList);

      setState(() {});
    } catch (e) {
      App.logger.severe(e);
    }
  }
}
