import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/archive_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/file_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/markdown_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/reply_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoceContentBubble extends StatelessWidget {
  final ChatMsgM chatMsgM;
  final UserInfoM userInfoM;

  final File? imageFile;

  final Archive? archive;

  // final ChatMsgM? repliedMsgM;
  // final UserInfoM? repliedMsgUserInfoM;
  // final File? repliedImageFile;

  final bool enableShowMoreBtn;

  VoceContentBubble.text(
      {required this.chatMsgM,
      required this.userInfoM,
      this.enableShowMoreBtn = true})
      : imageFile = null,
        archive = null;

  @override
  Widget build(BuildContext context) {
    switch (chatMsgM.detailType) {
      case MsgDetailType.normal:
        switch (chatMsgM.detailContentType) {
          case MsgContentType.text:
            String? content = "";
            bool hasMention = chatMsgM.hasMention;
            switch (chatMsgM.detailType) {
              case MsgDetailType.normal:
                content = chatMsgM.msgNormal?.content;
                break;
              case MsgDetailType.reply:
                content = chatMsgM.msgReply?.content;
                break;
              default:
            }

            return TextBubble(
                content: content ?? AppLocalizations.of(context)!.noContent,
                edited: chatMsgM.edited == 1,
                hasMention: hasMention,
                chatMsgM: chatMsgM,
                maxLines: 16,
                enableShowMoreBtn: true);

          case MsgContentType.markdown:
            return MarkdownBubble(
                markdownText: chatMsgM.msgNormal?.content ??
                    AppLocalizations.of(context)!.noContent,
                edited: chatMsgM.edited == 1);

          case MsgContentType.file:
            if (chatMsgM.isImageMsg) {
              return ImageBubble(
                  imageFile: imageFile,
                  getImageList: () => _getImageList(chatMsgM,
                      uid: chatMsgM.dmUid, gid: chatMsgM.gid));
            } else {
              final msgNormal = chatMsgM.msgNormal!;
              final name = msgNormal.properties?["name"] ?? "";
              final size = msgNormal.properties?["size"] ?? 0;
              return FileBubble(
                  filePath: msgNormal.content,
                  name: name,
                  size: size,
                  getLocalFile: () async {
                    return FileHandler.singleton.getLocalFile(chatMsgM);
                  },
                  getFile: (onProgress) async {
                    return FileHandler.singleton.getFile(chatMsgM, onProgress);
                  },
                  chatMsgM: chatMsgM);
            }
          // case MsgContentType.archive:
          //   return ArchiveBubble(
          //       archive: archive,
          //       archiveId: chatMsgM.msgNormal!.content,
          //       isSelecting: isSelecting.value,
          //       lengthLimit: 3,
          //       getFile: FileHandler.singleton.getArchiveFile);
          default:
        }
        break;
      // case MsgDetailType.reply:
      //   // if (repliedMsgM != null && repliedUserInfoM != null) {
      //   return Container(
      //     // color: Colors.amber,
      //     child: ReplyBubble(
      //         repliedMsgM: repliedMsgM,
      //         repliedUser: repliedUserInfoM!,
      //         repliedImageFile: repliedImageFile,
      //         msgM: chatMsgM),
      //   );
      // } else {
      //   return TextBubble(
      //     content: "The replied message has been deleted",
      //     maxLines: 16,
      //     enableShowMoreBtn: true,
      //     hasMention: false,
      //   );
      // }

      default:
    }
    return TextBubble(
        content: "Unsupported Message Type",
        hasMention: false,
        enableShowMoreBtn: false);
  }

  Future<ImageGalleryData> _getImageList(ChatMsgM centerMsgM,
      {int? uid, int? gid}) async {
    final centerMid = centerMsgM.mid;
    final preList = await ChatMsgDao()
        .getPreImageMsgBeforeMid(centerMid, uid: uid, gid: gid);

    final afterList = await ChatMsgDao()
        .getNextImageMsgAfterMid(centerMid, uid: uid, gid: gid);

    final initPage = preList != null ? preList.length : 0;

    return ImageGalleryData(
        imageItemList: (preList
                    ?.map((e) => SingleImageGetters(
                          getInitImageFile: () => _getLocalImageFileData(e),
                          getServerImageFile:
                              (isOriginal, imageNotifier, onReceiveProgress) =>
                                  _getServerImageFileData(isOriginal, e,
                                      imageNotifier, onReceiveProgress),
                        ))
                    .toList()
                    .reversed
                    .toList() ??
                []) +
            [
              SingleImageGetters(
                getInitImageFile: () => _getLocalImageFileData(centerMsgM),
                getServerImageFile:
                    (isOriginal, imageNotifier, onReceiveProgress) =>
                        _getServerImageFileData(isOriginal, centerMsgM,
                            imageNotifier, onReceiveProgress),
              )
            ] +
            (afterList
                    ?.map((e) => SingleImageGetters(
                          getInitImageFile: () => _getLocalImageFileData(e),
                          getServerImageFile:
                              (isOriginal, imageNotifier, onReceiveProgress) =>
                                  _getServerImageFileData(isOriginal, e,
                                      imageNotifier, onReceiveProgress),
                        ))
                    .toList() ??
                []),
        initialPage: initPage);
  }

  Future<SingleImageData?> _getLocalImageFileData(ChatMsgM chatMsgM) async {
    final localImageNormal =
        await FileHandler.singleton.getLocalImageNormal(chatMsgM);
    if (localImageNormal != null) {
      return SingleImageData(imageFile: localImageNormal, isOriginal: true);
    } else {
      final localImageThumb =
          await FileHandler.singleton.getLocalImageThumb(chatMsgM);
      if (localImageThumb != null) {
        return SingleImageData(imageFile: localImageThumb, isOriginal: false);
      }
    }
    return null;
  }

  Future<SingleImageData?> _getServerImageFileData(bool isOriginal,
      ChatMsgM chatMsgM, imageNotifier, onReceiveProgress) async {
    if (isOriginal) {
      return null;
    }

    final serverImageNormal = await FileHandler.singleton.getServerImageNormal(
      chatMsgM,
      onReceiveProgress: onReceiveProgress,
    );
    if (serverImageNormal != null) {
      imageNotifier.value = serverImageNormal;

      return SingleImageData(imageFile: serverImageNormal, isOriginal: true);
    } else {
      final serverImageThumb = await FileHandler.singleton.getServerImageThumb(
        chatMsgM,
        onReceiveProgress: onReceiveProgress,
      );
      if (serverImageThumb != null) {
        imageNotifier.value = serverImageThumb;
        isOriginal = false;
        return SingleImageData(imageFile: serverImageThumb, isOriginal: false);
      }
    }
    return null;
  }
}
