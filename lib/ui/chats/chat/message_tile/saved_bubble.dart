import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/saved_content_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/msg_tile_frame.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';

class SavedBubble extends StatelessWidget {
  final Archive? archive;
  final String filePath;
  final Future<File?> Function(int, String, int, bool) getSavedFiles;

  SavedBubble(
      {required this.archive,
      required this.filePath,
      required this.getSavedFiles});

  @override
  Widget build(BuildContext context) {
    if (archive == null) {
      return Text("Saved message might have been deleted.");
    }

    final users = archive!.users;
    final msgs = archive!.messages;

    double contentWidth = MediaQuery.of(context).size.width - 96;

    return Container(
      padding: EdgeInsets.all(8),
      // margin: EdgeInsets.only(top: 8, left: 8, right: 8),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(msgs.length, (index) {
          final msg = msgs[index];
          final user = users[msg.fromUser];

          if (user.avatar != null) {
            final avatarId = user.avatar!;
            return FutureBuilder<File?>(
                // Get sender avatar of archive msg.
                future: getSavedFiles(
                    App.app.userDb!.uid, filePath, avatarId, false),
                builder: (context, snapshot) {
                  File? avatarFile;
                  Widget child = CupertinoActivityIndicator();
                  if (snapshot.hasData) {
                    avatarFile = snapshot.data!;
                    child = SavedContentBubble(filePath, msg, getSavedFiles);
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: MsgTileFrame(
                        username: users[msg.fromUser].name,
                        nameColor: AppColors.grey600,
                        avatarFile: avatarFile,
                        avatarSize: VoceAvatarSize.s36,
                        timeStamp: msg.createdAt,
                        enableAvatarMention: false,
                        enableOnlineStatus: false,
                        enableUserDetailPush: false,
                        child: SizedBox(width: contentWidth, child: child)),
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
                avatarFile: null,
                avatarSize: VoceAvatarSize.s36,
                timeStamp: msg.createdAt,
                enableAvatarMention: false,
                enableOnlineStatus: false,
                enableUserDetailPush: false,
                child: SizedBox(
                  width: contentWidth,
                  child: SavedContentBubble(filePath, msg, getSavedFiles),
                ));
          }
        }),
      ),
    );
  }
}
