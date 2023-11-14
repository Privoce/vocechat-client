import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'round_button.dart';

class AvchatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? backButtonPressed;

  const AvchatAppBar({Key? key, this.backButtonPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color.fromRGBO(10, 10, 10, 0.9), Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: RoundButton(
          icon: CupertinoIcons.back,
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          size: 36,
          onPressed: backButtonPressed,
        ),
      ),
      title: Text('name'),
    );
  }

  @override
  Size get preferredSize => Size(double.infinity, 56);
}
