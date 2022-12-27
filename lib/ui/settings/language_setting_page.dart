import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/app_icon.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';

class LanguageSettingPage extends StatefulWidget {
  @override
  State<LanguageSettingPage> createState() => _LanguageSettingPageState();
}

class _LanguageSettingPageState extends State<LanguageSettingPage> {
  // Please keep Locale consistant with the ones in main.dart
  final List<LanguageItem> languageList = [
    LanguageItem(language: "简体中文", locale: Locale('zh', '')),
    LanguageItem(language: "English", locale: Locale('en', 'US'))
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.language,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        // actions: [
        //   CupertinoButton(
        //       onPressed: _onSubmit,
        //       child: Text(AppLocalizations.of(context)!.done,
        //           style: TextStyle(
        //               fontWeight: FontWeight.w400,
        //               fontSize: 17,
        //               color: AppColors.primary400)))
        // ],
      ),
      body: SafeArea(child: _buildLanguages()),
    );
  }

  Widget _buildLanguages() {
    return ListView(
      children: List.generate(languageList.length, (index) {
        final lang = languageList[index];
        final appLocale = Localizations.localeOf(context);

        final selected = appLocale == lang.locale;

        return BannerTile(
          title: lang.language,
          keepArrow: false,
          trailing: selected
              ? Icon(AppIcons.select, color: Colors.blue)
              : SizedBox.shrink(),
          onTap: () => _onTapLanguage(lang.locale),
        );
      }),
    );
  }

  void _onTapLanguage(Locale locale) {
    VoceChatApp.of(context)?.setLocale(locale);
  }

  void _onSubmit() {}
}

class LanguageItem {
  final String language;
  final Locale locale;

  LanguageItem({required this.language, required this.locale});
}
