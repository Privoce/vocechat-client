import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler/user_avatar_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/status.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/ui/auth/invitation_link_paste_page.dart';
import 'package:vocechat_client/ui/auth/server_account_tile.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';
import 'package:vocechat_client/ui/chats/chats/server_account_data.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatsDrawer extends StatefulWidget {
  const ChatsDrawer(
      {required this.disableGesture, Key? key, this.afterDrawerPop})
      : super(key: key);

  final void Function(bool isBusy) disableGesture;
  final VoidCallback? afterDrawerPop;

  @override
  State<ChatsDrawer> createState() => _ChatsDrawerState();
}

class _ChatsDrawerState extends State<ChatsDrawer> {
  List<ValueNotifier<ServerAccountData>> accountList = [];

  ValueNotifier<bool> isBusy = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _getServerData();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final titleStr = accountList.length > 1
        ? AppLocalizations.of(context)!.chatsDrawerServerAndAccountPl
        : AppLocalizations.of(context)!.chatsDrawerServerAndAccount;

    return Container(
        width: min(maxWidth, 320),
        height: double.maxFinite,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        titleStr,
                        style: AppTextStyles.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: isBusy,
                      builder: (context, isBusy, child) {
                        if (isBusy) {
                          return CupertinoActivityIndicator();
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    )
                  ],
                ),
              ),
              SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return Divider(indent: 86);
                  },
                  itemCount: accountList.length,
                  itemBuilder: (context, index) {
                    final accountData = accountList[index];
                    return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _switchUser(accountData.value),
                        child: ServerAccountTile(
                          accountData: accountData,
                          onLogoutTapped: _onLogoutTapped,
                        ));
                    // }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    VoceButton(
                      width: double.maxFinite,
                      contentColor: Colors.white,
                      decoration: BoxDecoration(
                          color: AppColors.primary400,
                          borderRadius: BorderRadius.circular(8)),
                      normal: Text(
                        AppLocalizations.of(context)!.chatsDrawerAddNewAccount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      ),
                      action: () async {
                        _onTapAddNewAccount();
                        return true;
                      },
                    ),
                    SizedBox(height: 16),
                    VoceButton(
                      width: double.maxFinite,
                      contentColor: Colors.white,
                      decoration: BoxDecoration(
                          color: AppColors.primary400,
                          borderRadius: BorderRadius.circular(8)),
                      normal: Text(
                        AppLocalizations.of(context)!.inputInvitationLink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      ),
                      action: () async {
                        _onTapPasteInvitationLink();
                        return true;
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }

  void _onTapAddNewAccount() async {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ServerPage(showClose: true),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
    Navigator.of(context).push(route);
  }

  void _onTapPasteInvitationLink() async {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          InvitationLinkPastePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
    Navigator.of(context).push(route);
  }

  void _switchUser(ServerAccountData accountData) async {
    final status = await StatusMDao.dao.getStatus();

    if (status?.userDbId == accountData.userDbM.id) {
      _jumpToMainPage();
      return;
    }

    widget.disableGesture(true);
    isBusy.value = true;

    await App.app.changeUser(accountData.userDbM);

    accountList.clear();
    await _getServerData();
    if (mounted) {
      setState(() {});
    }
    widget.disableGesture(false);
    isBusy.value = false;

    _jumpToMainPage();
  }

  void _jumpToMainPage() async {
    Navigator.pop(context);
    if (widget.afterDrawerPop != null) {
      await Future.delayed(Duration(milliseconds: 300));
      widget.afterDrawerPop!();
    }
  }

  Future<void> _getServerData() async {
    final userDbList = await UserDbMDao.dao.getList();

    final status = await StatusMDao.dao.getStatus();

    if (userDbList == null || userDbList.isEmpty || status == null) return;

    for (final userDb in userDbList) {
      final serverId = userDb.chatServerId;

      final chatServer = await ChatServerDao.dao.getServerById(serverId);

      final userAvatarBytes = await (await UserAvatarHandler().readOrFetch(
              UserInfoM.fromUserInfo(userDb.userInfo, ""),
              enableServerRetry: false,
              enableServerFetch: false))
          ?.readAsBytes();

      if (chatServer == null || userDb.loggedIn == 0) {
        continue;
      }

      accountList.add(ValueNotifier<ServerAccountData>(ServerAccountData(
          serverAvatarBytes: chatServer.logo,
          userAvatarBytes: userAvatarBytes ?? Uint8List(0),
          serverName: chatServer.properties.serverName,
          serverUrl: chatServer.fullUrl,
          username: userDb.userInfo.name,
          userEmail: userDb.userInfo.email!,
          selected: status.userDbId == userDb.id,
          userDbM: userDb)));
    }
    setState(() {});
  }

  void _onLogoutTapped() async {
    widget.disableGesture(true);
    isBusy.value = true;

    await App.app.authService?.logout().then((value) async {
      await App.app.changeUserAfterLogOut();
    });

    accountList.clear();
    await _getServerData();
    if (mounted) {
      setState(() {});
    }
    widget.disableGesture(false);
    isBusy.value = false;

    return;
  }
}
