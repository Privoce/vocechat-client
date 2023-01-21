import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_msg.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/file_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/markdown_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ArchiveContentBubble extends StatelessWidget {
  final ArchiveMsg archiveMsg;
  final String archiveId;
  final bool isFullPage;
  final Future<File?> Function(String, int, String) getFile;

  // final Future<ImageGalleryData?> getImageGalleryData;

  /// Archived text plain messages do not include replies. Only normal msgs.
  /// Archived msgs do not include [edited] info.
  ArchiveContentBubble(
      {required this.archiveId,
      required this.archiveMsg,
      required this.getFile,
      // required this.getImageGalleryData,
      this.isFullPage = true});

  @override
  Widget build(BuildContext context) {
    String errorMsg = "Unsupported type.";
    switch (archiveMsg.contentType) {
      case typeText:
        return TextBubble(
            content:
                archiveMsg.content ?? AppLocalizations.of(context)!.noContent,
            edited: false,
            maxLines: !isFullPage ? 8 : null,
            hasMention: true,
            enableCopy: isFullPage);
      case typeMarkdown:
        return MarkdownBubble(
            markdownText:
                archiveMsg.content ?? AppLocalizations.of(context)!.noContent,
            edited: false);
      case typeFile:
        if (archiveMsg.isImageMsg) {
          if (archiveMsg.thumbnailId != null) {
            return FutureBuilder<File?>(
                future: getFile(
                    archiveId, archiveMsg.thumbnailId!, archiveMsg.fileName),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ImageBubble(
                        imageFile: snapshot.data!,
                        getImageList: _getImageGalleryData);
                  } else {
                    return TextBubble(
                        content: archiveMsg.content ??
                            AppLocalizations.of(context)!.noContent,
                        edited: false,
                        hasMention: false,
                        maxLines: !isFullPage ? 8 : null);
                  }
                });
          } else {
            errorMsg = "Unsupported Image.";
          }
        } else {
          // Only show file tile in msg list. Raw file won't be saved to db.
          String? name = archiveMsg.properties?["name"];
          int? size = archiveMsg.properties?["size"];

          if (name != null && size != null) {
            return FileBubble(
                filePath: archiveId,
                name: name,
                size: size,
                getLocalFile: () => FileHandler.singleton
                    .getLocalArchiveFile(archiveId, archiveMsg.fileId!, name),
                getFile: (onProgress) async {
                  return FileHandler.singleton.getArchiveFile(
                      archiveId, archiveMsg.fileId!, name, onProgress);
                });
          }
        }
        break;
      default:
    }
    return TextBubble(
        content: "$errorMsg, ${archiveMsg.contentType}",
        edited: false,
        maxLines: !isFullPage ? 8 : null,
        hasMention: true);
  }

  Future<ImageGalleryData> _getImageGalleryData() async {
    // TODO: get a list of archive messages in this chat

    SingleImageGetters getters = SingleImageGetters(getInitImageFile: () async {
      final imageFile =
          await getFile(archiveId, archiveMsg.fileId!, archiveMsg.fileName);
      if (imageFile != null) {
        return SingleImageData(imageFile: imageFile, isOriginal: true);
      }
    });

    return ImageGalleryData(imageItemList: [getters], initialPage: 0);
  }
}
