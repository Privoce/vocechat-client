import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;

  const RoundButton(
      {Key? key,
      this.onPressed,
      required this.icon,
      this.backgroundColor,
      this.foregroundColor,
      this.size})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        width: size ?? 48,
        height: size ?? 48,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey[100],
            borderRadius:
                BorderRadius.circular(size != null ? (size! / 2) : 24)),
        child: Icon(icon,
            color: foregroundColor ?? Colors.grey,
            size: size != null ? (size! / 2) : 24),
      ),
    );
  }
}
