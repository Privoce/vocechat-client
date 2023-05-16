import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';

class VoceTileImageBubble extends StatefulWidget {
  final MsgTileData? tileData;

  final ChatMsgM? chatMsgM;
  final File? imageFile;

  late final Future<ImageGalleryData> Function() getImageList;

  final bool isReply;

  VoceTileImageBubble.tileData({Key? key, required MsgTileData this.tileData})
      : chatMsgM = tileData.chatMsgMNotifier.value,
        imageFile = tileData.imageFile,
        isReply = false,
        super(key: key) {
    getImageList = () => defaultGetImageList(chatMsgM!);
  }

  VoceTileImageBubble.data({
    Key? key,
    this.chatMsgM,
    this.imageFile,
    required this.getImageList,
    this.isReply = false,
  })  : tileData = null,
        super(key: key);

  static Future<ImageGalleryData> getSingleImageList(File imageFile) async {
    return ImageGalleryData(imageItemList: [
      SingleImageGetters(getInitImageFile: () async {
        return SingleImageData(imageFile: imageFile, isOriginal: true);
      }, getServerImageFile:
          (isOriginal, imageNotifier, onReceiveProgress) async {
        return SingleImageData(imageFile: imageFile, isOriginal: true);
      })
    ], initialPage: 0);
  }

  static Future<ImageGalleryData> defaultGetImageList(
    ChatMsgM centerMsgM,
  ) async {
    final centerMid = centerMsgM.mid;
    int? uid = centerMsgM.dmUid;
    int? gid = centerMsgM.gid;

    final preList = await ChatMsgDao()
        .getPreImageMsgBeforeMid(centerMid, uid: uid, gid: gid);

    final afterList = await ChatMsgDao()
        .getNextImageMsgAfterMid(centerMid, uid: uid, gid: gid);

    final initPage = preList != null ? preList.length : 0;

    return ImageGalleryData(
        imageItemList: (preList
                    ?.map((e) => SingleImageGetters(
                          getInitImageFile: () => getLocalImageFileData(e),
                          getServerImageFile:
                              (isOriginal, imageNotifier, onReceiveProgress) =>
                                  getServerImageFileData(isOriginal, e,
                                      imageNotifier, onReceiveProgress),
                        ))
                    .toList()
                    .reversed
                    .toList() ??
                []) +
            [
              SingleImageGetters(
                getInitImageFile: () => getLocalImageFileData(centerMsgM),
                getServerImageFile:
                    (isOriginal, imageNotifier, onReceiveProgress) =>
                        getServerImageFileData(isOriginal, centerMsgM,
                            imageNotifier, onReceiveProgress),
              )
            ] +
            (afterList
                    ?.map((e) => SingleImageGetters(
                          getInitImageFile: () => getLocalImageFileData(e),
                          getServerImageFile:
                              (isOriginal, imageNotifier, onReceiveProgress) =>
                                  getServerImageFileData(isOriginal, e,
                                      imageNotifier, onReceiveProgress),
                        ))
                    .toList() ??
                []),
        initialPage: initPage);
  }

  static Future<SingleImageData?> getLocalImageFileData(
      ChatMsgM chatMsgM) async {
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

  static Future<SingleImageData?> getServerImageFileData(bool isOriginal,
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

  @override
  State<VoceTileImageBubble> createState() => _VoceTileImageBubbleState();
}

class _VoceTileImageBubbleState extends State<VoceTileImageBubble> {
  Map<String, dynamic>? detailProperties;
  int? width;
  int? height;
  File? imageFile;
  late Future<ImageGalleryData> Function() getImageList;

  @override
  void initState() {
    super.initState();

    imageFile = widget.imageFile;
    getImageList = widget.getImageList;

    try {
      final detail =
          json.decode(widget.tileData!.chatMsgMNotifier.value.detail);
      detailProperties = detail['properties'];
      width = detailProperties?["width"] ?? 240;
      height = detailProperties?["height"] ?? 140;
    } catch (e) {
      App.logger.severe(e);
    }

    if (widget.tileData != null && widget.tileData!.needSecondaryPrepare) {
      widget.tileData!.secondaryPrepare().then((value) {
        if (mounted) {
          setState(() {
            try {
              final detail =
                  json.decode(widget.tileData!.chatMsgMNotifier.value.detail);
              detailProperties = detail['properties'];
              width = detailProperties?["width"] ?? 240;
              height = detailProperties?["height"] ?? 140;

              imageFile = widget.tileData!.imageFile;
              getImageList = () => VoceTileImageBubble.defaultGetImageList(
                  widget.tileData!.chatMsgMNotifier.value);
            } catch (e) {
              App.logger.severe(e);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tileData != null && widget.tileData!.needSecondaryPrepare) {
      // The constrains will remain the same as the original image.
      return Container(
          constraints: const BoxConstraints(maxHeight: 140),
          child: (width != null && height != null)
              ? AspectRatio(
                  aspectRatio: width! / height!,
                  // TODO: Add a loading progress indicator.
                  child: const CupertinoActivityIndicator(),
                )
              // TODO: add invalid image placeholder.
              : const SizedBox(
                  height: 140,
                  child: Text("invalid image info"),
                ));
    } else {
      if (widget.isReply) {
        return VoceImageBubble.reply(
            imageFile: imageFile, getImageList: getImageList);
      }
      return VoceImageBubble(imageFile: imageFile, getImageList: getImageList);
    }
  }
}
