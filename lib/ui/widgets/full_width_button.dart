import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class FullWidthButton extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final double? fontSize;
  final double cornerRadius;
  late Widget? trailing;
  final bool centerTitle;
  late final Color? fontColor;
  final Color? backgroundColor;

  final VoidCallback onPressed;

  FullWidthButton(
      {this.leadingIcon,
      required this.title,
      this.fontSize = 16,
      this.centerTitle = false,
      Color? fontColor,
      this.backgroundColor,
      this.cornerRadius = 10,
      required this.onPressed,
      Widget? trailing}) {
    this.fontColor = fontColor ?? AppColors.darkGrey;
    this.trailing =
        trailing ?? Icon(Icons.arrow_forward_ios, color: fontColor, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: backgroundColor != null ? backgroundColor! : Colors.white,
          borderRadius: BorderRadius.circular(cornerRadius)),
      child: CupertinoButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment:
              centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(right: 10),
                child: leadingIcon != null
                    ? Icon(leadingIcon, size: fontSize, color: fontColor)
                    : SizedBox.shrink()),
            Text(title,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: fontColor)),
            if (trailing != null) Spacer(),
            trailing ?? SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}
