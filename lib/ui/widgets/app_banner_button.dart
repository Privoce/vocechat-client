import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

// ignore: must_be_immutable
class AppBannerButton extends StatelessWidget {
  String? title;
  Widget? titleWidget;
  final VoidCallback? onTap;
  final Color? textColor;

  AppBannerButton({this.title, this.titleWidget, this.onTap, this.textColor}) {
    assert((title != null) ^ (titleWidget != null));
  }

  @override
  Widget build(BuildContext context) {
    titleWidget ??= Text(
      title!,
      textAlign: TextAlign.left,
      style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 17,
          color: textColor ?? AppColors.systemRed),
    );

    return Container(
      height: 48,
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.symmetric(
              horizontal: BorderSide(
                  width: 0.5, color: CupertinoColors.systemGroupedBackground))),
      child: TextButton(
          style: ElevatedButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
          ),
          child: Row(
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: titleWidget),
            ],
          ),
          onPressed: onTap),
    );
  }
}
