import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size(double.maxFinite, barHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.barBg,
      title: Text(
        AppLocalizations.of(context)!.settingsPageTitle,
        style: AppTextStyles.titleLarge(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
    );
  }
}
