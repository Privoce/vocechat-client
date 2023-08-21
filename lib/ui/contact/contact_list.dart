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

  /// The initial contact list.
  ///
  /// It could be set empty.
  final List<UserInfoM> initUserList;
  final Function(UserInfoM userInfoM) onTap;
  final bool enableSelect;
  final double avatarSize;
  final ValueNotifier<List<int>>? selectNotifier;
  final List<int>? preSelectUidList;
  final bool enablePreSelectAction;

  /// Whether to enable contact list update.
  ///
  /// If enabled, any change to the contact list, including user adding, updating
  /// or deleting will appear. If not, contact list will be static.
  ///
  /// Set to true by default.
  final bool enableUpdate;

  /// Whether to only include all users from [initUserList].
  ///
  /// In channel member lists, we need to show all users from [initUserList], but
  /// some users may not be in contact list, if contact mode is enabled in server
  /// settings. However, in Contacts Page, we only need to show users in contact
  /// list. In this case, we need to set [onlyShowInitList] to false.
  final bool onlyShowInitList;
  final int? ownerUid;

  const ContactList(
      {required this.initUserList,
      required this.onTap,
      this.avatarSize = VoceAvatarSize.s36,
      this.enableSelect = false,
      this.selectNotifier,
      this.preSelectUidList,
      this.enablePreSelectAction = true,
      this.enableUpdate = true,
      this.onlyShowInitList = false,
      this.ownerUid,
      Key? key})
      : super(key: key);

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList>
    with AutomaticKeepAliveClientMixin {
  // List<UserInfoM> _contactList = [];
  // final Set<int> _uidSet = {};
  Map<int, UserInfoM> _contactMap = {};

  bool isPreparing = false;

  /// Whether contact mode is enabled in server settings.
  ValueNotifier<bool> enableContact = ValueNotifier(true);

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();

    enableContact.value =
        App.app.chatServerM.properties.commonInfo?.contactVerificationEnable ==
            true;

    // if (_shouldOnlyShowContacts) {
    //   _contactList = widget.initUserList.where((element) {
    //     return element.contactStatus == ContactStatus.added ||
    //         element.uid == App.app.userDb?.uid;
    //   }).toList();
    // } else {
    //   _contactList = widget.initUserList;
    // }
    _contactMap = {for (var e in widget.initUserList) e.uid: e};

    if (widget.enableUpdate) {
      App.app.chatService.subscribeUsers(_onUser);
      App.app.chatService.subscribeReady(_onReady);
    }

    App.app.chatService.subscribeChatServer(_onChatServerChange);
  }

  /// If the contact list only contains contacts of the current user.
  ///
  /// It should fulfill the following conditions:
  /// 1. Contact mode is enabled in server settings.
  /// 2. Current user is not admin.
  ///
  /// Admins can always see all users in the server.
  bool get _shouldInclude {
    return App.app.userDb?.userInfo.isAdmin != true && enableContact.value;
  }

  @override
  void dispose() {
    if (widget.enableUpdate) {
      App.app.chatService.unsubscribeReady(_onReady);
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
    final contactList = _contactMap.values.toList();
    _sortList(contactList);

    return AzListView(
      data: contactList,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: contactList.length,
      itemBuilder: (context, index) {
        final user = contactList[index];
        final isSelf = user.uid == App.app.userDb?.uid;
        final preSelected =
            widget.preSelectUidList?.contains(user.uid) ?? false;
        Widget? ownerMark;

        if (user.uid == widget.ownerUid) {
          ownerMark = Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color: AppColors.primaryBlue,
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
      indexBarData: SuspensionUtil.getTagIndexList(contactList),
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

  /// Handle user create/update/delete event.
  ///
  /// If the following criteria are met, the user will be added to the contact
  /// list:
  /// 1. Contact mode is enabled, following are in OR relationship:
  ///  a. User is my contact (added).
  ///  b. User is myself.
  ///  c. User is admin.
  /// 2. Anyone if contact mode is disabled.
  /// 3. Anyone if I am an admin.
  Future<void> _onUser(
      UserInfoM userInfoM, EventActions action, bool afterReady) async {
    try {
      switch (action) {
        case EventActions.create:
        case EventActions.update:
          if (widget.onlyShowInitList && action == EventActions.create) {
            break;
          }
          if (App.app.userDb?.userInfo.isAdmin == true) {
            _contactMap.addAll({userInfoM.uid: userInfoM});
            break;
          } else if (!enableContact.value) {
            _contactMap.addAll({userInfoM.uid: userInfoM});
            break;
          } else if (userInfoM.contactStatus == ContactStatus.added ||
              userInfoM.uid == App.app.userDb?.uid ||
              App.app.userDb?.userInfo.isAdmin == true) {
            _contactMap.addAll({userInfoM.uid: userInfoM});
            break;
          } else {
            break;
          }

        case EventActions.delete:
          _contactMap.remove(userInfoM.uid);
          break;
        default:
          break;
      }
    } catch (e) {
      App.logger.severe(e);
    }

    setState(() {});
  }

  Future<void> _onChatServerChange(ChatServerM chatServerM) async {
    if (widget.onlyShowInitList) {
      return;
    }

    enableContact.value =
        chatServerM.properties.commonInfo?.contactVerificationEnable == true;

    await UserInfoDao().getUserList().then((value) {
      if (value != null) {
        _contactMap = {for (var e in value) e.uid: e};
        setState(() {});
      }
    });
  }

  /// Sort the contact list by A-Z tag.
  ///
  /// TODO: order might not be consistent if Pinyin is involved. Should be
  /// optimized in the future.
  void _sortList(List<UserInfoM> contactList) {
    if (isPreparing) {
      return;
    }

    isPreparing = true;
    try {
      // A-Z sort.
      SuspensionUtil.sortListBySuspensionTag(contactList);

      // show sus tag.
      SuspensionUtil.setShowSuspensionStatus(contactList);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      App.logger.severe(e);
    }
    isPreparing = false;
  }

  Future<void> _onReady({bool clearAll = false}) async {
    if (mounted) {
      setState(() {});
    }
  }
}
