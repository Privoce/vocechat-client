import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class SheetAppBar extends StatelessWidget {
  final double height;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;

  SheetAppBar({this.height = 60, this.title, this.leading, this.actions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
            height: 12,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                        color: AppColors.grey400,
                        borderRadius: BorderRadius.circular(25))),
              ),
            )),
        SizedBox(
          width: double.maxFinite,
          height: height,
          child: NavigationToolbar(
            leading: leading,
            middle: title,
            centerMiddle: true,
            trailing: (actions != null && actions!.isNotEmpty)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions!)
                : null,
          ),
        ),
      ],
    );
  }
}
