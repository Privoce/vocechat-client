import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/settings/changelog_models.dart/change_log.dart';

class SettingsChangelogPage extends StatelessWidget {
  final ChangeLog? changeLog;

  SettingsChangelogPage({required this.changeLog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        centerTitle: true,
        title: Text("VoceChat Changelog",
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
    if (changeLog == null || changeLog!.logs.isEmpty) {
      return Text("Can't find changelog in voce.chat.");
    } else {
      return ListView.separated(
        itemCount: changeLog!.logs.length,
        itemBuilder: (context, index) {
          final historyItem = changeLog!.logs[index];

          final version = historyItem.version;
          final date = DateTime.fromMillisecondsSinceEpoch(historyItem.time);
          final dateString = DateFormat('MM/dd/yyyy').format(date);
          final logs = historyItem.updates;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text("$version\t($dateString)",
                  style: AppTextStyles.titleLarge),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(logs.length, (i) {
                    return Text(logs[i]);
                  })),
            ),
          );
        },
        separatorBuilder: (context, index) => Divider(),
      );
    }
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
}
