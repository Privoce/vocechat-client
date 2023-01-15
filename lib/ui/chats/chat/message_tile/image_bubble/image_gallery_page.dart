import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_page.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({Key? key, required this.initImageItem})
      : super(key: key);

  final SingleImageItem initImageItem;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final PageController _controller;
  final List<SingleImageItem> _imageList = [];
  final Set<String> _imageLocalMidSet = {};

  @override
  void initState() {
    super.initState();

    _controller = PageController(keepPage: true);
    _addToEnd(widget.initImageItem);
  }

  void _addToFront(SingleImageItem item) {
    if (!_imageLocalMidSet.contains(item.chatMsgM.localMid)) {
      _imageLocalMidSet.add(item.chatMsgM.localMid);
      _imageList.insert(0, item);
    }
  }

  void _addToEnd(SingleImageItem item) {
    if (!_imageLocalMidSet.contains(item.chatMsgM.localMid)) {
      _imageLocalMidSet.add(item.chatMsgM.localMid);
      _imageList.add(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: PageView.builder(
          controller: _controller,
          allowImplicitScrolling: true,
          itemCount: _imageList.length,
          physics: Platform.isIOS
              ? BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
              : AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = _imageList[index];

            return SingleImagePage(
                initImageFile: item.initImageFile,
                loadOriginalImageFileCallBack: ((progressIndicator) {}));
          },
        ));
  }
}
