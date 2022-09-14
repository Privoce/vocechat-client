import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class SettingsActionButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback onTap;

  const SettingsActionButton(
      {Key? key, required this.icon, required this.text, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        constraints: BoxConstraints(
            maxHeight: 68, maxWidth: 80, minHeight: 20, minWidth: 24),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(height: 7),
            Text(
              text,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: AppColors.grey500),
            )
          ],
        )),
      ),
    );
  }
}
