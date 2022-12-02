import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_html/js.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/settings/changelog_models.dart/change_log.dart';
import 'package:vocechat_client/ui/widgets/app_icon.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';
import 'package:http/http.dart' as http;

class SettingsAboutPage extends StatelessWidget {
  final ValueNotifier<bool> _isCheckingUpdates = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    _getChangeLog();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        centerTitle: true,
        title: Text("About VoceChat",
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
      bottomNavigationBar: SafeArea(
          child: Text(
        "© Privoce Inc. All Rights Reserved.",
        textAlign: TextAlign.center,
      )),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        AppIcon(),
        SizedBox(height: 16),
        _buildAppInfo(),
        SizedBox(height: 32),
        _buildActions(context)
      ],
    );
  }

  Widget _buildAppInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("VoceChat", style: AppTextStyles.titleLarge),
        FutureBuilder<String>(
            future: _getAppVersion(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text("Version: ${snapshot.data!}",
                    style: AppTextStyles.labelMedium);
              } else {
                return SizedBox.shrink();
              }
            })
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return BannerTileGroup(bannerTileList: [
      BannerTile(
        title: "Check Updates",
        titleWidget: ValueListenableBuilder<bool>(
          valueListenable: _isCheckingUpdates,
          builder: (context, value, child) {
            if (value) {
              return CupertinoActivityIndicator();
            } else {
              return SizedBox.shrink();
            }
          },
        ),
        onTap: () {
          _checkUpdates(context);
        },
      ),
      BannerTile(title: "Changelog")
    ]);
  }

  Future<String> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;
    // return version + "($buildNumber)";
    return version;
  }

  void _checkUpdates(BuildContext context) async {
    _isCheckingUpdates.value = true;

    final changeLog = await _getChangeLog();

    if (changeLog == null) {
      _showNetworkError(context);
      _isCheckingUpdates.value = false;
      return;
    }

    final latestVersion = changeLog.latest.version;
    final localVersion = await _getAppVersion();

    if (latestVersion.compareTo(localVersion) > 0) {
      _showUpdates(context, latestVersion);
    } else {
      _showUpToDate(context);
    }

    _isCheckingUpdates.value = false;
  }

  Future<ChangeLog?> _getChangeLog() async {
    try {
      const logUrl = "https://vocechat.s3.amazonaws.com/changelog.json";
      final res = await http.get(Uri.parse(logUrl));
      return ChangeLog.fromJson(jsonDecode(res.body));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  void _showNetworkError(BuildContext context) {
    showAppAlert(
        context: context,
        title: "Network Error",
        content:
            "VoceChat cannot fetch latest version information. You may try it later.",
        actions: [
          AppAlertDialogAction(
              text: "OK", action: () => Navigator.of(context).pop())
        ]);
  }

  void _showUpdates(BuildContext context, String latestVersionNum) {
    List<AppAlertDialogAction> actions = [];
    if (Platform.isIOS) {
      actions.add(AppAlertDialogAction(text: "App Store", action: (() {})));
    } else if (Platform.isAndroid) {
      actions.addAll([
        AppAlertDialogAction(text: "Play Store", action: (() {})),
        AppAlertDialogAction(text: "APK", action: (() {}))
      ]);
    }

    actions.add(AppAlertDialogAction(
        text: "Cancel",
        action: (() {
          Navigator.of(context).pop();
        })));

    showAppAlert(
        context: context,
        title: "Update Available",
        content: "A newer version $latestVersionNum is available.",
        actions: actions);
  }

  void _showUpToDate(BuildContext context) {
    showAppAlert(
        context: context,
        title: "You are Up-to-date",
        content: "You are using the latest VoceChat App.",
        actions: [
          AppAlertDialogAction(
              text: "OK",
              action: (() {
                Navigator.of(context).pop();
              }))
        ]);
  }
}
