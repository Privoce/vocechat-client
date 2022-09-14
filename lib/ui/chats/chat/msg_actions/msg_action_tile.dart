import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class MsgActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  MsgActionTile(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        icon,
        size: 24,
        color: color ?? AppColors.grey600,
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: color ?? AppColors.grey600)),
    );
  }
}
