import 'dart:convert';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NewDmPage extends StatefulWidget {
  const NewDmPage({Key? key}) : super(key: key);

  @override
  State<NewDmPage> createState() => _NewDmPageState();
}

class _NewDmPageState extends State<NewDmPage> {
  final List<UserInfoM> _contactList = [];
  final Set<int> _uidSet = {};

  @override
  void initState() {
    super.initState();
    _getContactList();
    App.app.chatService.subscribeUsers(_onUser);
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeUsers(_onUser);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.coolGrey200,
        title: Text(AppLocalizations.of(context)!.newDmPageTitle,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Icon(Icons.close, color: AppColors.grey97)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TextField(),
            Expanded(
                child: ContactList(
                    userList: _contactList,
                    onTap: (user) {
                      Navigator.of(context).pop(user);
                    }))
          ],
        ),
      ),
    );
  }

  Widget _buildSusWidget(String susTag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      height: 20,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          Text(
            susTag,
            textScaleFactor: 1.2,
          ),
        ],
      ),
    );
  }

  Future<void> _onUser(UserInfoM userInfoM, EventActions action) async {
    final userInfo = UserInfo.fromJson(jsonDecode(userInfoM.info));
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
          App.logger.severe("User with uid: ${userInfoM.uid} not found in UI.");
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
  }

  void _getContactList() async {
    try {
      final contactList = await UserInfoDao().getUserList();
      if (contactList != null && contactList.isNotEmpty) {
        if (contactList.length == _uidSet.length) {
          return;
        }
        for (var contact in contactList) {
          if (_uidSet.contains(contact.uid)) {
            continue;
          }
          final userInfo = UserInfo.fromJson(jsonDecode(contact.info));
          _uidSet.add(contact.uid);
          _contactList.add(contact);
        }

        // A-Z sort.
        SuspensionUtil.sortListBySuspensionTag(_contactList);

        // show sus tag.
        SuspensionUtil.setShowSuspensionStatus(_contactList);
      }
      setState(() {});
    } catch (e) {
      App.logger.severe(e);
    }
  }
}
