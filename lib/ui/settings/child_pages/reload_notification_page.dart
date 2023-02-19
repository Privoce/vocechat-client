import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/token_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/settings/changelog_models.dart/change_log.dart';
import 'package:vocechat_client/ui/settings/child_pages/settings_changelog_page.dart';
import 'package:vocechat_client/ui/widgets/app_icon.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class ReloadNotificationPage extends StatelessWidget {
  final ValueNotifier<bool> _isResetting = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.resetFcmToken,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BannerTileGroup(
      bannerTileList: [
        BannerTile(
          title: AppLocalizations.of(context)!.resetFcmToken,
          keepArrow: false,
          titleWidget: ValueListenableBuilder<bool>(
            valueListenable: _isResetting,
            builder: (context, value, child) {
              if (value) {
                return Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: CupertinoActivityIndicator());
              } else {
                return SizedBox.shrink();
              }
            },
          ),
          onTap: _reset,
        )
      ],
      footer: AppLocalizations.of(context)!.resetFcmTokenFooter,
    );
  }

  void _reset() async {
    _isResetting.value = true;

    final deviceToken = await App.app.authService!.getFirebaseDeviceToken();
    final currentContext = navigatorKey.currentContext!;

    if (deviceToken.isNotEmpty) {
      try {
        final res = await TokenApi().updateFcmDeviceToken(deviceToken);

        if (res.statusCode == 200) {
          if (currentContext.mounted) {
            Navigator.of(currentContext).pop();
            return;
          }
        }
      } catch (e) {
        App.logger.severe(e);
      }
    }

    _isResetting.value = false;

    if (currentContext.mounted) {
      await showAppAlert(
          context: currentContext,
          title: AppLocalizations.of(navigatorKey.currentContext!)!
              .noFCMTokenReloadTitle,
          content: AppLocalizations.of(navigatorKey.currentContext!)!
              .noFCMTokenReloadDes,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(currentContext)!.ok,
                action: (() => Navigator.of(currentContext).pop()))
          ]);
    }
  }
}
