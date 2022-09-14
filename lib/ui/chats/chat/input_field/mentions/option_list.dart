import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

class OptionList extends StatelessWidget {
  OptionList({
    required this.users,
    required this.onTap,
    required this.suggestionListHeight,
    this.suggestionListDecoration,
  });

  final List<UserInfoM> users;

  final Function(UserInfoM) onTap;

  final double suggestionListHeight;

  final BoxDecoration? suggestionListDecoration;

  @override
  Widget build(BuildContext context) {
    return users.isNotEmpty
        ? Container(
            decoration:
                suggestionListDecoration ?? BoxDecoration(color: Colors.white),
            constraints: BoxConstraints(
              maxHeight: suggestionListHeight,
              minHeight: 0,
            ),
            child: ListView.builder(
              itemCount: users.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onTap(users[index]);
                  },
                  child: Container(
                    // width: MediaQuery.of(context).size.width,
                    // color: Colors.amber,
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      users[index].userInfo.name,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          )
        : Container();
  }
}
