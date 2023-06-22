import 'dart:async';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/contacts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/contact/contact_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';

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
      this.avatarSize = VoceAvatarSize.s36,
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

  bool isPreparing = false;

  ValueNotifier<bool> enableContact = ValueNotifier(true);

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();

    enableContact.value =
        App.app.chatServerM.properties.commonInfo?.contactVerificationEnable ==
            true;

    if (enableContact.value) {
      _contactList = widget.userList
          .where((element) => element.contactStatus == ContactStatus.added)
          .toList();
    } else {
      _contactList = widget.userList;
    }

    _uidSet.addAll(_contactList.map((e) => e.uid));

    _prepareContactList();

    if (widget.enableUserUpdate) {
      App.app.chatService.subscribeUsers(_onUser);
      App.app.chatService.subscribeRefresh(() {
        if (mounted) {
          setState(() {});
        }
      });
    }

    App.app.chatService.subscribeChatServer(_onChatServerChange);
  }

  @override
  void dispose() {
    if (widget.enableUserUpdate) {
      App.app.chatService.unsubscribeRefresh(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
    App.app.chatService.unsubscribeUsers(_onUser);
    App.app.chatService.unsubscribeChatServer(_onChatServerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                        key: ObjectKey(user),
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
      physics: const BouncingScrollPhysics(),
      indexBarData: SuspensionUtil.getTagIndexList(_contactList),
      indexHintBuilder: (context, hint) {
        return Container(
          alignment: Alignment.center,
          width: 60.0,
          height: 60.0,
          decoration: const BoxDecoration(
            color: Colors.cyan,
            shape: BoxShape.circle,
          ),
          child: Text(hint,
              style: const TextStyle(color: Colors.white, fontSize: 30.0)),
        );
      },
      indexBarMargin: const EdgeInsets.all(10),
      indexBarOptions: const IndexBarOptions(
          hapticFeedback: HapticFeedback.mediumImpact,
          indexHintAlignment: Alignment.centerRight,
          needRebuild: true),
    );
  }

  Widget _buildSusWidget(String susTag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    if (enableContact.value) {
      if (userInfoM.contactStatusStr != ContactStatus.added.name) {
        return;
      }
    }

    switch (action) {
      case EventActions.create:
      case EventActions.update:
        // Should handle one special case: add self to contact list anyway.
        if (SharedFuncs.isSelf(userInfoM.uid)) {
          _uidSet.add(userInfoM.uid);

          final index = _contactList
              .indexWhere((element) => element.uid == userInfoM.uid);
          if (index > -1) {
            _contactList[index] = userInfoM;
          } else {
            _contactList.add(userInfoM);
          }
          break;
        }

        // Then handle general case.
        if (enableContact.value) {
          if (userInfoM.contactStatusStr == ContactStatus.added.name) {
            _uidSet.add(userInfoM.uid);

            final index = _contactList
                .indexWhere((element) => element.uid == userInfoM.uid);
            if (index > -1) {
              _contactList[index] = userInfoM;
            } else {
              _contactList.add(userInfoM);
            }
          } else {
            _uidSet.remove(userInfoM.uid);
            _contactList.removeWhere((element) => element.uid == userInfoM.uid);
          }
        } else {
          _uidSet.add(userInfoM.uid);

          final index = _contactList
              .indexWhere((element) => element.uid == userInfoM.uid);
          if (index > -1) {
            _contactList[index] = userInfoM;
          } else {
            _contactList.add(userInfoM);
          }
        }
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

    if (afterReady) {
      _prepareContactList();
    }
  }

  Future<void> _onChatServerChange(ChatServerM chatServerM) async {
    if (chatServerM.properties.commonInfo?.contactVerificationEnable == true) {
      enableContact.value = true;
    } else {
      enableContact.value = false;
    }

    if (enableContact.value) {
      _contactList = widget.userList
          .where((element) => element.contactStatus == ContactStatus.added)
          .toList();
    } else {
      _contactList = widget.userList;
    }

    _prepareContactList();
  }

  void _prepareContactList() {
    if (isPreparing) {
      return;
    }

    isPreparing = true;
    try {
      // A-Z sort.
      SuspensionUtil.sortListBySuspensionTag(_contactList);

      // show sus tag.
      SuspensionUtil.setShowSuspensionStatus(_contactList);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      App.logger.severe(e);
    }
    isPreparing = false;
  }
}
