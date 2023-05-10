import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_msg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/file_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/markdown_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SavedContentBubble extends StatelessWidget {
  final ArchiveMsg archiveMsg;
  final String archiveId;
  final Future<File?> Function(int, String, int, bool) getSavedFiles;

  /// Saved text plain messages do not include replies. Only normal msgs.
  /// Saved msgs do not include [edited] info.
  SavedContentBubble(this.archiveId, this.archiveMsg, this.getSavedFiles);

  @override
  Widget build(BuildContext context) {
    String errorMsg = "Unsupported type.";
    switch (archiveMsg.contentType) {
      case typeText:
        return TextBubble(
            content:
                archiveMsg.content ?? AppLocalizations.of(context)!.noContent,
            edited: false,
            hasMention: true,
            enableShowMoreBtn: true,
            maxLines: 10);
      case typeMarkdown:
        return MarkdownBubble(
            markdownText:
                archiveMsg.content ?? AppLocalizations.of(context)!.noContent,
            edited: false);
      case typeFile:
        if (archiveMsg.isImageMsg) {
          // Only show thumb in chat list.
          if (archiveMsg.thumbnailId != null) {
            return FutureBuilder<File?>(
                // Get thumb of an image archive msg.
                future: getSavedFiles(App.app.userDb!.uid, archiveId,
                    archiveMsg.thumbnailId!, false),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final tag = archiveId + archiveMsg.thumbnailId.toString();

                    return VoceImageBubble(
                        imageFile: snapshot.data!,
                        getImageList: () async {
                          return ImageGalleryData(imageItemList: [
                            SingleImageGetters(
                              getInitImageFile: () async {
                                final imageFile = await getSavedFiles(
                                    App.app.userDb!.uid,
                                    archiveId,
                                    archiveMsg.fileId!,
                                    false);
                                if (imageFile != null) {
                                  return SingleImageData(
                                      imageFile: imageFile, isOriginal: true);
                                }
                                return null;
                              },
                            )
                          ], initialPage: 0);
                        });
                  } else {
                    return TextBubble(
                        content: archiveMsg.content ??
                            AppLocalizations.of(context)!.noContent,
                        edited: false,
                        hasMention: false);
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
              getLocalFile: () => FileHandler.singleton.getLocalSavedItemsFile(
                  App.app.userDb!.uid, archiveId, archiveMsg.fileId!, name),
              getFile: (onProgress) async {
                return FileHandler.singleton.getSavedItemsFile(
                    App.app.userDb!.uid,
                    archiveId,
                    archiveMsg.fileId!,
                    name,
                    onProgress);
                // String url = App.app.chatServerM.fullUrl;
                // url += "/api/resource/archive/attachment?file_path=$archiveId";
                // url += "&attachment_id=${archiveMsg.fileId!}&download=true";
                // try {
                //   await launchUrlString(url);
                // } catch (e) {
                //   App.logger.warning(e);
                // }
              },
            );
          }
        }
        break;
      default:
    }
    return TextBubble(
        content: "$errorMsg, ${archiveMsg.contentType}",
        edited: false,
        hasMention: false);
  }
}
