import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/pinned_msg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/archive_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/file_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/markdown_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/msg_tile_frame.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';

class PinnedMsgTile extends StatelessWidget {
  final UserInfoM userInfoM;
  final PinnedMsg msg;
  final int gid;

  PinnedMsgTile(
      {required this.gid, required this.msg, required this.userInfoM});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      // margin: EdgeInsets.only(left: 12, right: 12),
      padding: EdgeInsets.all(8),
      child: MsgTileFrame(
          username: userInfoM.userInfo.name,
          avatarBytes: userInfoM.avatarBytes,
          timeStamp: msg.createdAt,
          enableAvatarMention: false,
          enableOnlineStatus: false,
          enableUserDetailPush: false,
          child: SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: _buildContent())),
    );
  }

  Widget _buildContent() {
    switch (msg.contentType) {
      case typeText:
        return TextBubble(
            content: msg.content,
            hasMention: true,
            maxLines: 10,
            enableShowMoreBtn: true);
      case typeMarkdown:
        return MarkdownBubble(markdownText: msg.content);
      case typeFile:
        if (msg.isImageMsg) {
          return _buildImageBubble(msg);
        } else {
          return _buildFileBubble(msg);
        }
      case typeArchive:
        return FutureBuilder<ArchiveM?>(
            future: ArchiveDao().getArchive(msg.content),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return ArchiveBubble(
                    archive: snapshot.data!.archive!,
                    archiveId: msg.content,
                    getFile: FileHandler.singleton.getArchiveFile);
              } else {
                return TextBubble(
                    content: "Unsupported Message Type.", hasMention: false);
              }
            });

      default:
    }
    return Text(msg.content);
  }

  Widget _buildFileBubble(PinnedMsg msg) {
    final chatId = getChatId(gid: gid);
    String fileName = msg.properties!["name"] ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final name = msg.properties!["name"] ?? "";
    final size = msg.properties!["size"] ?? 0;
    final filePath = msg.content;
    return FileBubble(
        filePath: filePath,
        name: name,
        size: size,
        getLocalFile: () => getLocalFile(chatId!, filePath, fileName),
        getFile: (onProgress) async {
          return getMsgFile(chatId!, filePath, fileName, onProgress);
        });
  }

  Widget _buildImageBubble(PinnedMsg msg) {
    try {
      final chatId = getChatId(gid: gid);
      String imageName = msg.properties!["name"] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      return FutureBuilder<File?>(
          future: getThumbImage(chatId!, msg.content, imageName),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ImageBubble(
                imageFile: snapshot.data!,
                getImageList: () async {
                  return ImageGalleryData(imageItemList: [
                    SingleImageGetters(
                      getInitImageFile: () async {
                        final originalImage = await getOriginalImage(
                            chatId, msg.content, imageName);
                        if (originalImage != null) {
                          return SingleImageData(
                              imageFile: originalImage, isOriginal: true);
                        }
                      },
                    )
                  ], initialPage: 0);
                },
              );
            }
            return CupertinoActivityIndicator();
          });
    } catch (e) {
      App.logger.severe(e);
      return TextBubble(content: "Unsupported Message Type", hasMention: false);
    }
  }

  Future<File?> getThumbImage(
      String chatId, String filePath, String imageName) async {
    final thumbFile =
        await FileHandler.singleton.readImageThumb(chatId, filePath, imageName);
    if (thumbFile != null) {
      return thumbFile;
    }

    try {
      final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
      final res = await resourceApi.getFile(filePath, true, false);

      if (res.statusCode == 200 && res.data != null) {
        return FileHandler.singleton
            .saveImageThumb(chatId, res.data!, filePath, imageName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> getOriginalImage(
      String chatId, String filePath, String imageName) async {
    final imageFile = await FileHandler.singleton
        .readImageNormal(chatId, filePath, imageName);
    if (imageFile != null) {
      return imageFile;
    }

    try {
      final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
      final res = await resourceApi.getFile(filePath, false, false);

      if (res.statusCode == 200 && res.data != null) {
        return await FileHandler.singleton
            .saveImageNormal(chatId, res.data!, filePath, imageName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> getLocalFile(
      String chatId, String filePath, String fileName) async {
    if (await FileHandler.singleton.fileExists(chatId, filePath, fileName)) {
      final file =
          await FileHandler.singleton.readFile(chatId, filePath, fileName);
      return file;
    }
    return null;
  }

  Future<File?> getMsgFile(String chatId, String filePath, String fileName,
      Function(int, int) onProgress) async {
    if (await FileHandler.singleton.fileExists(chatId, filePath, fileName)) {
      final file =
          await FileHandler.singleton.readFile(chatId, filePath, fileName);
      return file;
    }

    ResourceApi resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
    try {
      final res = await resourceApi.getFile(filePath, false, true, onProgress);
      if (res.statusCode == 200 && res.data != null) {
        return FileHandler.singleton
            .saveFile(chatId, res.data!, filePath, fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }
}
