import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/services/file_handler.dart';

class VoceImageBubble extends StatelessWidget {
  final MsgTileData tileData;

  const VoceImageBubble.tileData({super.key, required this.tileData});

  Future<VoceGalleryData> generateGalleryData(MsgTileData tileData) async {
    final centerMsgM = tileData.chatMsgMNotifier.value;

    final centerMid = centerMsgM.mid;
    int? uid = centerMsgM.dmUid;
    int? gid = centerMsgM.gid;

    final preList = await ChatMsgDao()
        .getPreImageMsgBeforeMid(centerMid, uid: uid, gid: gid);

    final afterList = await ChatMsgDao()
        .getNextImageMsgAfterMid(centerMid, uid: uid, gid: gid);

    final initIndex = preList != null ? preList.length : 0;

    return VoceGalleryData(
        images: (preList
                    ?.map((e) {
                      return VoceImageData(
                          getInitImage: ({onReceiveProgress}) => getInitImage(e,
                              onReceiveProgress: onReceiveProgress),
                          getOriginalImage: ({onReceiveProgress}) =>
                              getOriginalImage(e));
                    })
                    .toList()
                    .reversed
                    .toList() ??
                []) +
            [
              VoceImageData(
                  getInitImage: ({onReceiveProgress}) => getInitImage(
                      centerMsgM,
                      onReceiveProgress: onReceiveProgress),
                  getOriginalImage: ({onReceiveProgress}) =>
                      getOriginalImage(centerMsgM))
            ] +
            (afterList?.map((e) {
                  return VoceImageData(
                      getInitImage: ({onReceiveProgress}) =>
                          getInitImage(e, onReceiveProgress: onReceiveProgress),
                      getOriginalImage: ({onReceiveProgress}) =>
                          getOriginalImage(e));
                }).toList() ??
                []),
        initIndex: initIndex);

    // return VoceGalleryData(images: images, initialIndex: initialIndex)
  }

  /// Get the initial image file for [VoceImageBubble].
  ///
  /// If the image file is already downloaded, return the local file.
  /// Get local original image first, if not exist, get thumbnail.
  /// Fetch for thumbnail from server if not.
  static Future<InitImageData> getInitImage(ChatMsgM chatMsgM,
      {Function(int, int)? onReceiveProgress}) async {
    File? file = await FileHandler.singleton.getLocalImageNormal(chatMsgM);
    if (file != null) {
      return InitImageData(file: file, isOriginal: true);
    }

    file = await FileHandler.singleton
        .getImageThumb(chatMsgM, onReceiveProgress: onReceiveProgress);
    return InitImageData(file: file, isOriginal: false);
  }

  static Future<File?> getOriginalImage(ChatMsgM chatMsgM,
      {Function(int, int)? onReceiveProgress}) async {
    return FileHandler.singleton
        .getImageNormal(chatMsgM, onReceiveProgress: onReceiveProgress);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class InitImageData {
  final File? file;
  final bool isOriginal;

  InitImageData({required this.file, this.isOriginal = false});
}

class VoceGalleryData {
  final List<VoceImageData> images;
  final int initIndex;

  /// The data needed for a gallery of images for [VoceImageBubble]
  VoceGalleryData({
    required this.images,
    required this.initIndex,
  });
}

class VoceImageData {
  final Future<InitImageData> Function({Function(int, int)? onReceiveProgress})
      getInitImage;

  final Future<File?> Function({Function(int, int)? onReceiveProgress})?
      getOriginalImage;

  /// The data needed for a single image item for [VoceImageBubble]
  VoceImageData({
    required this.getInitImage,
    this.getOriginalImage,
  });
}
