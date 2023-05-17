import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';

class SingleImageGetters {
  // final ChatMsgM chatMsgM;

  bool isOriginal = false;

  late Future<SingleImageData?> Function() getLocalImageFile;
  late Future<SingleImageData?> Function(
      bool isOriginal,
      ValueNotifier<File> imageNotifier,
      Function(int progress, int total) onReceiveProgress)? getServerImageFile;

  SingleImageGetters(
      {required Future<SingleImageData?> Function() getInitImageFile,
      Future<SingleImageData?> Function(
              bool isOriginal,
              ValueNotifier<File> imageNotifier,
              Function(int progress, int total) onReceiveProgress)?
          getServerImageFile}) {
    this.getLocalImageFile = () async {
      final data = await getInitImageFile();
      isOriginal = data?.isOriginal ?? false;
      return data;
    };

    if (getServerImageFile != null) {
      this.getServerImageFile =
          (isOriginal, imageNotifier, onReceiveProgress) async {
        final data = await getServerImageFile(
            isOriginal, imageNotifier, onReceiveProgress);
        isOriginal = data?.isOriginal ?? false;
        return data;
      };
    } else {
      this.getServerImageFile = null;
    }
  }
}
