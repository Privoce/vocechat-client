import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/services/sse.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/auth/login_page.dart';
import 'package:vocechat_client/ui/chats/chats/new/invite_user_page.dart';
import 'package:vocechat_client/ui/chats/chats/new/new_channel_page.dart';
import 'package:vocechat_client/ui/chats/chats/new/new_dm_page.dart';
import 'package:vocechat_client/ui/widgets/search/app_search_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum AddActions { channel, private, dm, user }

class ChatsBar extends StatefulWidget implements PreferredSizeWidget {
  late final Widget _avatar;
  late final bool _isAdmin;
  late final String _serverDescription;
  final VoidCallback showDrawer;

  // If enabled, Server description will be displayed, instead of member count.
  final bool enableDescription = true;

  final ValueNotifier<int> memberCountNotifier;
  final void Function(GroupInfoM groupInfoM) onCreateChannel;
  final void Function(UserInfoM userInfoM) onCreateDm;
  // final void Function() onInviteUser;

  @override
  // Size get preferredSize => Size(double.maxFinite, 98);
  Size get preferredSize => Size(double.maxFinite, barHeight);

  ChatsBar(
      {required this.onCreateChannel,
      required this.onCreateDm,
      // required this.onInviteUser,
      required this.memberCountNotifier,
      required this.showDrawer,
      Key? key})
      : super(key: key) {
    if (App.app.chatServerM.logo.isEmpty) {
      _avatar = CircleAvatar(
        child: Text(App.app.chatServerM.properties.serverName[0].toUpperCase()),
      );
    } else {
      _avatar = Container(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: DecorationImage(
                fit: BoxFit.scaleDown,
                image: MemoryImage(App.app.chatServerM.logo))),
      );
    }

    _isAdmin =
        UserInfo.fromJson(jsonDecode(App.app.userDb!.info)).isAdmin ?? false;

    _serverDescription = App.app.chatServerM.properties.description ?? "";
  }

  @override
  State<ChatsBar> createState() => _ChatsBarState();
}

class _ChatsBarState extends State<ChatsBar> {
  final double _tileHeight = 50;
  late LoadingStatus _sseStatus;
  late TokenStatus _tokenStatus;
  late LoadingStatus _taskStatus;

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sseStatus = LoadingStatus.success;
    _tokenStatus = TokenStatus.success;
    _taskStatus = LoadingStatus.success;
    App.app.statusService.subscribeSseLoading(_onSse);
    App.app.statusService.subscribeTokenLoading(_onToken);
    App.app.statusService.subscribeTaskLoading(_onTask);

    eventBus.on<UserChangeEvent>().listen((event) {
      resubscribe();
    });
  }

  @override
  void dispose() {
    App.app.statusService.unsubscribeSseLoading(_onSse);
    App.app.statusService.unsubscribeTokenLoading(_onToken);
    App.app.statusService.unsubscribeTaskLoading(_onTask);
    super.dispose();
  }

  void resubscribe() {
    App.app.statusService.unsubscribeSseLoading(_onSse);
    App.app.statusService.unsubscribeTokenLoading(_onToken);
    App.app.statusService.unsubscribeTaskLoading(_onTask);

    _sseStatus = LoadingStatus.success;
    _tokenStatus = TokenStatus.success;
    _taskStatus = LoadingStatus.success;
    App.app.statusService.subscribeSseLoading(_onSse);
    App.app.statusService.subscribeTokenLoading(_onToken);
    App.app.statusService.subscribeTaskLoading(_onTask);
  }

  Future<void> _onSse(LoadingStatus status) async {
    if (mounted) {
      setState(() {
        _sseStatus = status;
      });
    }
  }

  Future<void> _onToken(TokenStatus status) async {
    if (mounted) {
      setState(() {
        _tokenStatus = status;
      });
    }
  }

  Future<void> _onTask(LoadingStatus status) async {
    if (mounted) {
      setState(() {
        _taskStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.barBg,
      leadingWidth: 47,
      leading: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => widget.showDrawer(),
            child: widget._avatar),
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  App.app.chatServerM.properties.serverName,
                  style: AppTextStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.enableDescription &&
                    widget._serverDescription.isNotEmpty)
                  Text(
                    widget._serverDescription,
                    style: AppTextStyles.labelSmall,
                  )
                else
                  ValueListenableBuilder<int>(
                      valueListenable: widget.memberCountNotifier,
                      builder: (context, memberCount, _) {
                        String subtitle;
                        if (memberCount > 1) {
                          subtitle = "$memberCount members";
                        } else {
                          subtitle = "$memberCount member";
                        }

                        return Text(
                          subtitle,
                          style: AppTextStyles.labelSmall,
                        );
                      })
              ],
            ),
          ),
          _buildStatus(),
        ],
      ),
      centerTitle: false,
      actions: [
        // IconButton(
        //     onPressed: () async {
        //       // print(await GroupInfoDao().getMutedChannelList());
        //       Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
        //         return NewPage();
        //       })));
        //     },
        //     icon: Text(
        //       "test",
        //       style: TextStyle(color: Colors.black),
        //     )),
        Padding(
            padding: EdgeInsets.only(right: 10),
            child: PopupMenuButton(
              icon: Icon(Icons.add, color: AppColors.darkGrey, size: 24),
              splashRadius: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              offset: Offset(0.0, 50.0),
              onSelected: (action) async {
                switch (action as AddActions) {
                  case AddActions.channel:
                    final route = PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          NewChannelPage(
                        enablePublic: widget._isAdmin && enablePublicChannels,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.fastOutSlowIn;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    );
                    final groupInfoM = await Navigator.push(context, route);
                    if (groupInfoM != null) {
                      widget.onCreateChannel(groupInfoM);
                    }
                    break;

                  case AddActions.dm:
                    final route = PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          NewDmPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.fastOutSlowIn;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    );
                    final userInfoM = await Navigator.push(context, route);
                    if (userInfoM != null) {
                      widget.onCreateDm(userInfoM);
                    }
                    break;
                  case AddActions.user:
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8))),
                        builder: (sheetContext) {
                          return FractionallySizedBox(
                            heightFactor: 0.3,
                            child: InviteUserPage(),
                          );
                        });

                    break;

                  default:
                }
              },
              itemBuilder: (context) {
                return [
                  _buildItem(
                      Icon(AppIcons.channel, color: AppColors.grey97),
                      AppLocalizations.of(context)!.chatsBarNewChannel,
                      AddActions.channel),
                  _buildItem(
                      Icon(AppIcons.dm, color: AppColors.grey97),
                      AppLocalizations.of(context)!.chatsBarNewDm,
                      AddActions.dm),
                  _buildItem(Icon(AppIcons.member_add, color: AppColors.grey97),
                      "Invite People", AddActions.user)
                ];
              },
            ))
      ],
      // bottom: tabBar
      // bottom: AppSearchField(AppLocalizations.of(context)!.chatsPageSearchHint),
    );
  }

  Widget _buildStatus() {
    print("SSE: $_sseStatus");
    print("TOKEN: $_tokenStatus");
    print("TASK: $_taskStatus");
    if (_sseStatus == LoadingStatus.success &&
        _tokenStatus == TokenStatus.success &&
        _taskStatus == LoadingStatus.success) {
      return SizedBox.shrink();
    } else if (_tokenStatus == TokenStatus.unauthorized) {
      return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showAppAlert(
                context: context,
                title: "Login Status Expired",
                content: "Please login again.",
                actions: [
                  AppAlertDialogAction(
                      text: "Cancel",
                      action: (() async {
                        Navigator.of(context).pop();
                      })),
                  AppAlertDialogAction(
                      text: "OK",
                      action: (() async {
                        Navigator.of(context).pop();
                        // Call login page
                        _reLogin();
                      }))
                ]);
          },
          child: Icon(Icons.error, color: Colors.red.shade600));
    } else if (_sseStatus == LoadingStatus.loading ||
        _tokenStatus == TokenStatus.loading ||
        _taskStatus == LoadingStatus.loading) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: CupertinoActivityIndicator(color: AppColors.coolGrey700),
      );
    } else if (_sseStatus == LoadingStatus.disconnected ||
        _tokenStatus == TokenStatus.disconnected ||
        _taskStatus == LoadingStatus.disconnected) {
      return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showAppAlert(
                context: context,
                title: "Network Error",
                content:
                    "Please check your network settings, or try to log in again.",
                actions: [
                  AppAlertDialogAction(
                      text: "OK",
                      action: (() async {
                        Navigator.of(context).pop();
                        // await App.app.authService?.renewAuthToken();
                        // Sse.sse.connect();
                      }))
                ]);
          },
          child: Icon(Icons.error, color: Colors.red.shade600));
    }

    return SizedBox.shrink();
  }

  void _reLogin() async {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => LoginPage(
          chatServerM: App.app.chatServerM,
          email: App.app.userDb!.userInfo.email),
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

  PopupMenuItem _buildItem(Widget leading, String title, AddActions action) {
    return PopupMenuItem<AddActions>(
        height: _tileHeight,
        padding: EdgeInsets.only(left: 10),
        value: action,
        child: Row(
          children: [
            leading,
            SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge,
              ),
            )
          ],
        ));
  }
}
