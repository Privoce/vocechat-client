import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A horizontally expanded button based on CupertinoButton.
///
/// Leave [onTap] null if wants to disable a button.
class BannerButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? leading;
  final String title;
  final Color? backgroundColor;
  final Color fontColor;

  BannerButton(
      {required this.onTap,
      required this.title,
      this.backgroundColor,
      this.fontColor = Colors.white,
      this.leading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: CupertinoButton(
          disabledColor: CupertinoColors.quaternaryLabel,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: backgroundColor ?? Theme.of(context).primaryColor,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) leading!,
                if (leading != null) SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fontColor)),
              ],
            ),
          ),
          onPressed: onTap),
    );
  }
}
