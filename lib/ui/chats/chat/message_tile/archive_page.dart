import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_msg.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/archive_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_archive_bubble.dart';

class ArchivePage extends StatelessWidget {
  final Archive? archive;
  final String filePath;
  final bool isSelecting;
  final Future<File?> Function(String, int, String) getFile;

  ArchivePage(
      {required this.archive,
      required this.filePath,
      this.isSelecting = false,
      required this.getFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VoceArchiveBubble.data(
              archive: archive, archiveId: filePath, isFullPage: true),
        ),
      )),
    );
  }
}
