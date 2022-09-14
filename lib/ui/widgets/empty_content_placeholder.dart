import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

class EmptyContentPlaceholder extends StatelessWidget {
  final String text;
  final double iconSize;

  EmptyContentPlaceholder({required this.text, this.iconSize = 140});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.emoji_surprise,
            size: iconSize,
            color: AppColors.grey300,
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.grey600,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }
}
