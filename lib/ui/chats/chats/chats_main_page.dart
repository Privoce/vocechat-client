import 'package:flutter/cupertino.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chats/chats_drawer.dart';
import 'package:vocechat_client/ui/chats/chats/chats_page.dart';
import 'package:vocechat_client/ui/contact/contacts_page.dart';
import 'package:vocechat_client/ui/settings/settings_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatsMainPage extends StatefulWidget {
  static const route = '/chats';

  ChatsMainPage({Key? key}) : super(key: key);

  final double _iconsize = 30;
  final Color _defaultColor = Colors.grey.shade400;
  final Color _activeColor = Colors.grey.shade800;

  @override
  State<ChatsMainPage> createState() => _ChatsMainPageState();
}

class _ChatsMainPageState extends State<ChatsMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pageOptions = <Widget>[
    ChatsPage(),
    ContactsPage(),
    SettingPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
            height: 60,
            activeColor: widget._activeColor,
            inactiveColor: widget._defaultColor,
            items: [
              _buildChatsIcon(),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Icon(AppIcons.contact, size: widget._iconsize),
                ),
                label: AppLocalizations.of(context)!.tabContacts,
              ),
              BottomNavigationBarItem(
                icon: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                    child: Icon(AppIcons.setting, size: widget._iconsize)),
                label: AppLocalizations.of(context)!.tabSettings,
              ),
            ]),
        tabBuilder: (context, index) {
          return _pageOptions[index];
        });
  }

  BottomNavigationBarItem _buildChatsIcon() {
    Widget unreadBadge = ValueListenableBuilder<int>(
        valueListenable: globals.unreadCountSum,
        builder: (context, unreadCount, _) {
          if (unreadCount < 1) {
            return SizedBox.shrink();
          }
          String text = unreadCount.toString();
          if (unreadCount > 99) {
            text = "99+";
          }
          return Positioned(
            top: 4,
            right: 0,
            child: Container(
                constraints: BoxConstraints(minWidth: 20),
                height: 20,
                decoration: BoxDecoration(
                    color: AppColors.primaryHover,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      text,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10),
                    ),
                  ),
                )),
          );
        });

    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Icon(AppIcons.chat, size: widget._iconsize),
          ),
          unreadBadge
        ],
      ),
      activeIcon: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Icon(AppIcons.chat, size: widget._iconsize),
          ),
          unreadBadge
        ],
      ),
      label: AppLocalizations.of(context)!.tabChats,
    );
  }

  Widget _buildDrawer() {
    return ChatsDrawer();
  }
}
