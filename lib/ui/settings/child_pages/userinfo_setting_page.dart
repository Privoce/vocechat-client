import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/settings/child_pages/password_setting_page.dart';
import 'package:vocechat_client/ui/settings/child_pages/userinfo_detail_setting_page.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';

class UserInfoSettingPage extends StatefulWidget {
  const UserInfoSettingPage({Key? key, required this.userInfoNotifier})
      : super(key: key);

  final ValueNotifier<UserInfoM?> userInfoNotifier;

  @override
  State<UserInfoSettingPage> createState() => _UserInfoSettingPageState();
}

class _UserInfoSettingPageState extends State<UserInfoSettingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          toolbarHeight: barHeight,
          elevation: 0,
          backgroundColor: AppColors.barBg,
          title: Text(AppLocalizations.of(context)!.userSettings,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge),
          leading: CupertinoButton(
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BannerTile(
                  title: AppLocalizations.of(context)!.userInfo,
                  keepTrailingArrow: true,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserInfoDetailSettingPage(
                              widget.userInfoNotifier)))),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BannerTile(
                  title: AppLocalizations.of(context)!.changePassword,
                  keepTrailingArrow: true,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PasswordSettingPage()))),
            ),
          ],
        ));
  }
}
