import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/empty_data_placeholder.dart';
import 'package:vocechat_client/ui/widgets/empty_content_placeholder.dart';

class VoceImageBubble extends StatefulWidget {
  // final ChatMsgM chatMsgM;
  final Future<ImageGalleryData> Function() getImageList;
  final File? imageFile;

  final bool _isReply;

  const VoceImageBubble(
      {super.key, required this.imageFile, required this.getImageList})
      : _isReply = false;

  const VoceImageBubble.reply(
      {super.key, required this.imageFile, required this.getImageList})
      : _isReply = true;

  @override
  State<VoceImageBubble> createState() => _VoceImageBubbleState();
}

class _VoceImageBubbleState extends State<VoceImageBubble> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints(maxHeight: widget._isReply ? 24 : 140),
        child: widget.imageFile == null
            ? TextBubble(
                content: AppLocalizations.of(context)!.imageBeDeletedDes,
                hasMention: false)
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                              return const EmptyDataPlaceholder();
                            }
                          }));
                },
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
              ));
  }
}

class ImageGalleryData {
  final List<SingleImageGetters> imageItemList;
  final int initialPage;

  ImageGalleryData({required this.imageItemList, required this.initialPage});
}
