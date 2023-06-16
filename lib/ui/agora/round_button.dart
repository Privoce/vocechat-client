import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double? paddingValue;
  final VoidCallback? onPressed;

  const RoundButton(
      {Key? key,
      required this.icon,
      this.color,
      this.backgroundColor,
      this.size = 24,
      this.paddingValue = 16,
      this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = (size + 16 * 2) / 2;
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
            decoration: BoxDecoration(
                color: backgroundColor ?? Colors.grey[800],
                borderRadius: BorderRadius.circular(radius)),
            child: Center(
                child: Padding(
              padding: EdgeInsets.all(paddingValue ?? 16),
              child: Icon(icon, size: size, color: color ?? Colors.white),
            ))));
  }
}
