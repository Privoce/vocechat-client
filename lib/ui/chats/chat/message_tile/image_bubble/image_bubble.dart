import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/fade_page_route.dart';
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
                child: Hero(
                    tag: widget.localMid,
                    child: Image.file(widget.imageFile!, fit: BoxFit.contain)),
                onTap: () {
                  Navigator.of(context).push(FadePageRoute(
                      interBarrierColor: Colors.black,
                      child: ImagePage(
                          initImageFile: widget.imageFile!,
                          heroTag: widget.localMid,
                          getImage: widget.getImage)));
                },
              ));
  }
}
