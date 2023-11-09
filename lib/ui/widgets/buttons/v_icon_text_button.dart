import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VIconTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData icon;
  final Color? color;
  final Color? textColor;
  final double? iconSize;
  final double? fontSize;
  final double? height;
  final double? width;
  final double? radius;
  final EdgeInsets? padding;
  final bool? enable;

  const VIconTextButton(
      {Key? key,
      required this.onPressed,
      required this.text,
      required this.icon,
      this.color,
      this.textColor,
      this.iconSize,
      this.fontSize,
      this.height,
      this.width,
      this.radius,
      this.padding,
      this.enable})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: enable == true ? onPressed : null,
      color: color ?? Colors.grey[100],
      borderRadius: BorderRadius.circular(radius ?? 4),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor ?? Colors.grey[500],
            size: iconSize ?? 24,
          ),
          SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: textColor ?? Colors.grey[500], fontSize: fontSize ?? 12),
          )
        ],
      ),
    );
  }
}
