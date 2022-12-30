import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/archive_content_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/archive_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/msg_tile_frame.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ArchiveBubble extends StatelessWidget {
  final Archive? archive;
  final String archiveId;
  final bool isSelecting;
  final Future<File?> Function(String, int, String) getFile;
  final int? lengthLimit;
  final bool isFullPage;

  ArchiveBubble(
      {required this.archive,
      required this.archiveId,
      this.isSelecting = false,
      required this.getFile,
      this.lengthLimit,
      this.isFullPage = false});

  @override
  Widget build(BuildContext context) {
    if (archive == null) {
      return TextBubble(
          content: "Message data might have been deleted.", hasMention: false);
    }

    final users = archive!.users;
    final msgs = archive!.messages;

    final listLength =
        lengthLimit == null ? msgs.length : min(lengthLimit! + 1, msgs.length);

    // 16 + 48 + 8 + 8 + 24 + 8 + 8 + 16 + 50
    double contentWidth;
    if (!isFullPage) {
      contentWidth = MediaQuery.of(context).size.width - 186;
    } else {
      contentWidth = MediaQuery.of(context).size.width - 80;
    }

    if (isSelecting) contentWidth -= 30;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isFullPage
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ArchivePage(
                  archive: archive, filePath: archiveId, getFile: getFile))),
      child: AbsorbPointer(
        absorbing: !isFullPage,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), color: AppColors.grey100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.forward, size: 12, color: AppColors.grey400),
                  SizedBox(width: 4),
                  Text(AppLocalizations.of(context)!.forwarded,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: AppColors.grey400))
                ],
              ),
              SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(listLength, (index) {
                  if (index == lengthLimit) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "and ${msgs.length - lengthLimit!} more...",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    );
                  }

                  final msg = msgs[index];
                  final user = users[msg.fromUser];

                  if (user.avatar != null) {
                    final avatarId = user.avatar!;
                    return FutureBuilder<File?>(
                        // Get sender avatar of archive msg.

                        future: getFile(archiveId, avatarId, msg.fileName),
                        builder: (context, snapshot) {
                          Uint8List avatarBytes = Uint8List(0);
                          Widget child = CupertinoActivityIndicator();
                          if (snapshot.hasData) {
                            avatarBytes = snapshot.data!.readAsBytesSync();
                            child = ArchiveContentBubble(
                              archiveId: archiveId,
                              archiveMsg: msg,
                              getFile: getFile,
                              isFullPage: isFullPage,
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: MsgTileFrame(
                                username: users[msg.fromUser].name,
                                nameColor: AppColors.grey600,
                                avatarBytes: avatarBytes,
                                avatarSize: AvatarSize.s24,
                                timeStamp: msg.createdAt,
                                enableAvatarMention: false,
                                enableOnlineStatus: false,
                                enableUserDetailPush: false,
                                contentWidth: contentWidth,
                                child: SizedBox(
                                    width: contentWidth, child: child)),
                          );
                        });
                  } else {
                    // avatar, fileid, thumbId are indexes of attachments,
                    // starting from 0
                    // from_user is the index in [users] list；
                    // file path in chatMsg
                    return MsgTileFrame(
                        username: users[msg.fromUser].name,
                        nameColor: AppColors.grey600,
                        avatarBytes: Uint8List(0),
                        avatarSize: AvatarSize.s24,
                        timeStamp: msg.createdAt,
                        enableAvatarMention: false,
                        enableOnlineStatus: false,
                        enableUserDetailPush: false,
                        contentWidth: contentWidth,
                        child: SizedBox(
                            width: contentWidth,
                            child: ArchiveContentBubble(
                              archiveId: archiveId,
                              archiveMsg: msg,
                              getFile: getFile,
                              isFullPage: isFullPage,
                            )));
                  }
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
