import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/app_icon.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';
import 'package:http/http.dart' as http;

class SettingsAboutPage extends StatelessWidget {
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
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: SafeArea(
          child: Text(
        "© Privoce Inc. All Rights Reserved.",
        textAlign: TextAlign.center,
      )),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        AppIcon(),
        SizedBox(height: 16),
        _buildAppInfo(),
        SizedBox(height: 32),
        _buildActions()
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

  Widget _buildActions() {
    return BannerTileGroup(bannerTileList: [
      BannerTile(title: "Check Updates"),
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

  Future<Map<String, dynamic>?> _getChangeLog() async {
    final logUrl = "https://vocechat.s3.amazonaws.com/changelog.json";
    final res = await http.get(Uri.parse(logUrl));
    return jsonDecode(res.body)["latest"];
  }
}
