import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AvChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(children: [_buildBar(context)]);
  }

  Widget _buildBar(BuildContext context) {
    return Row(children: [
      roundButton(Icons.arrow_back_ios, 20, onPressed: () {}),
      Spacer(),
      roundButton(Icons.more_horiz, 20, onPressed: () {}),
    ]);
  }

  Widget roundButton(IconData icon, double size, {VoidCallback? onPressed}) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icon, size: size, color: Colors.white));
  }
}
