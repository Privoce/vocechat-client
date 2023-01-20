import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';

class ChatImageBubble extends StatefulWidget {
  // final ChatMsgM chatMsgM;
  final Future<ImageGalleryData> Function() getImageList;
  final File? imageFile;

  ChatImageBubble({required this.imageFile, required this.getImageList});

  @override
  State<ChatImageBubble> createState() => _ChatImageBubbleState();
}

class _ChatImageBubbleState extends State<ChatImageBubble> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.centerLeft,
        constraints: BoxConstraints(maxHeight: 140),
        child: widget.imageFile == null
            ? TextBubble(
                content: AppLocalizations.of(context)!.imageBeDeletedDes,
                hasMention: false)
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Image.file(widget.imageFile!, fit: BoxFit.contain,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    return child;
                  } else {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: frame != null
                          ? child
                          : const CupertinoActivityIndicator(),
                    );
                  }
                }),
                onTap: () {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => FutureBuilder<ImageGalleryData?>(
                          future: widget.getImageList(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ImageGalleryPage(data: snapshot.data!);
                            } else {
                              return Text("Empty");
                            }
                          }));
                },
              ));
  }
}

class ImageGalleryData {
  final List<SingleImageGetters> imageItemList;
  final int initialPage;

  ImageGalleryData({required this.imageItemList, required this.initialPage});
}
