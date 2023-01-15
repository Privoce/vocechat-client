import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/chats/chat/image_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';

class ImageBubble extends StatefulWidget {
  final String localMid;
  final File? imageFile;
  final Future<File?> Function() getImage;

  ImageBubble(
      {required this.imageFile,
      required this.localMid,
      required this.getImage});

  @override
  State<ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<ImageBubble> {
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
                      builder: (context) => ImagePage(
                          initImageFile: widget.imageFile!,
                          getImage: widget.getImage));
                },
              ));
  }
}
