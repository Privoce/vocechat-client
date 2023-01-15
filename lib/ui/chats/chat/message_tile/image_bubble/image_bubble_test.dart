import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/ui/chats/chat/image_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';

class ImageBubbleTest extends StatefulWidget {
  final ChatMsgM chatMsgM;
  final File? imageFile;
  final Future<File?> Function() getImage;

  ImageBubbleTest(
      {required this.imageFile,
      required this.chatMsgM,
      required this.getImage});

  @override
  State<ImageBubbleTest> createState() => _ImageBubbleTestState();
}

class _ImageBubbleTestState extends State<ImageBubbleTest> {
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
                content: "Image might have been deleted.", hasMention: false)
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
                      builder: (context) => ImageGalleryPage(
                          initImageItem: SingleImageItem(
                              initImageFile: widget.imageFile!,
                              chatMsgM: widget.chatMsgM)));
                },
              ));
  }
}
