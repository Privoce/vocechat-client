import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';

class ListGroup extends StatelessWidget {
  final String? groupTitle;
  final List<Widget> children;

  ListGroup({this.groupTitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(left: 18, top: 5, bottom: 5),
            child: groupTitle != null
                ? Text(
                    groupTitle!,
                    style: TextStyle(
                        color: AppColors.coolGrey500,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  )
                : SizedBox.shrink()),
        Column(children: children)
      ],
    );
  }
}
