import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';

class SingleImageItem {
  final ChatMsgM chatMsgM;

  bool isOriginal = false;
  late Future<SingleImageData?> Function() getLocalImageFile;
  late Future<File?> Function(ValueNotifier<File> imageNotifier,
      Function(int progress, int total) onReceiveProgress) getServerImageFile;

  Future<SingleImageData?> _getLocalImageFileData(ChatMsgM chatMsgM) async {
    final localImageNormal =
        await FileHandler.singleton.getLocalImageNormal(chatMsgM);
    if (localImageNormal != null) {
      isOriginal = true;
      return SingleImageData(imageFile: localImageNormal, isOriginal: true);
    } else {
      final localImageThumb =
          await FileHandler.singleton.getLocalImageThumb(chatMsgM);
      if (localImageThumb != null) {
        isOriginal = false;
        return SingleImageData(imageFile: localImageThumb, isOriginal: false);
      }
    }
    return null;
  }

  SingleImageItem({required this.chatMsgM}) {
    getLocalImageFile = () => _getLocalImageFileData(chatMsgM);

    getServerImageFile = (imageNotifier, onReceiveProgress) async {
      if (isOriginal) {
        return null;
      }

      final serverImageNormal =
          await FileHandler.singleton.getServerImageNormal(
        chatMsgM,
        onReceiveProgress: onReceiveProgress,
      );
      if (serverImageNormal != null) {
        imageNotifier.value = serverImageNormal;
        isOriginal = true;
        return serverImageNormal;
      } else {
        final serverImageThumb =
            await FileHandler.singleton.getServerImageThumb(
          chatMsgM,
          onReceiveProgress: onReceiveProgress,
        );
        if (serverImageThumb != null) {
          imageNotifier.value = serverImageThumb;
          isOriginal = false;
          return serverImageThumb;
        }
      }
      return null;
    };
  }
}
