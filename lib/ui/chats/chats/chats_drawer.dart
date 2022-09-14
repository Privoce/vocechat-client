import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/ui/auth/login_page.dart';

class ChatsDrawer extends StatelessWidget {
  const ChatsDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: double.maxFinite,
      color: Colors.blue.shade100,
      child: FutureBuilder<List<UserDbM>?>(
        future: UserDbMDao.dao.getList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final serverList = snapshot.data!;
            return ListView.builder(
              itemCount: serverList.length,
              itemBuilder: (context, index) {
                final server = serverList[index];
                // final userInfo = UserInfoJson.fromJson(json.decode(server.userInfo));
                return FutureBuilder<ChatServerM?>(
                  future: ChatServerDao.dao.getServerById(server.chatServerId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox.shrink();
                    }
                    return ServerDrawerTile(chatServerM: snapshot.data!);
                  },
                );
              },
            );
          }
          return SizedBox(
              width: 30,
              height: 30,
              child: Center(child: CupertinoActivityIndicator()));
        },
      ),
    );
  }
}

class ServerDrawerTile extends StatelessWidget {
  final bool selected;
  final ChatServerM chatServerM;
  final VoidCallback? onTap;

  late Widget _logo;

  ServerDrawerTile(
      {this.selected = false, required this.chatServerM, this.onTap, Key? key})
      : super(key: key) {
    if (chatServerM.logo.isEmpty) {
      _logo = CircleAvatar(child: Text(chatServerM.properties.serverName));
    } else {
      _logo = CircleAvatar(foregroundImage: MemoryImage(chatServerM.logo));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
          height: 50,
          width: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(left: 5, right: 5),
                width: 20,
                child: Icon(
                  Icons.circle,
                  size: 10,
                ),
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                      height: 50,
                      width: 50,
                      color: Colors.yellow,
                      child: _logo)),
            ],
          )),
    );
  }
}
