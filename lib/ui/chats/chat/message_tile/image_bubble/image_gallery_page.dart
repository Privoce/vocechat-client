import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
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

  bool _isAddingPre = false;
  bool _isAddingNext = false;

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

      _imageList.sort(((a, b) => a.chatMsgM.mid.compareTo(b.chatMsgM.mid)));
    }
  }

  void _addToEnd(SingleImageItem item) {
    if (!_imageLocalMidSet.contains(item.chatMsgM.localMid)) {
      _imageLocalMidSet.add(item.chatMsgM.localMid);
      _imageList.add(item);

      _imageList.sort(((a, b) => a.chatMsgM.mid.compareTo(b.chatMsgM.mid)));
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
            _addImage(item, index);

            return SingleImagePage(
                initImageFile: item.initImageFile,
                loadOriginalImageFileCallBack: ((progressIndicator) {}));
          },
        ));
  }

  void _addImage(SingleImageItem currItem, int index) async {
    for (final each in _imageList) {
      print(each.chatMsgM.msgNormal?.content);
    }
    if (index <= 1) {
      await _addPreImages(currItem);
    }
    if (index >= _imageList.length - 2) {
      await _addNextImages(currItem);
    }
  }

  Future<void> _addPreImages(SingleImageItem currItem) async {
    if (_isAddingPre) {
      return;
    } else {
      _isAddingPre = true;
      final msg = await ChatMsgDao().getPreImageMsgBeforeMid(
          currItem.chatMsgM.mid,
          uid: currItem.chatMsgM.dmUid,
          gid: currItem.chatMsgM.gid);
      if (msg != null) {
        final imageFile = await _getImageFile(msg);
        if (imageFile != null && mounted) {
          setState(() {
            _addToFront(
                SingleImageItem(initImageFile: imageFile, chatMsgM: msg));
          });
        }
      }

      _isAddingPre = false;
    }
  }

  Future<void> _addNextImages(SingleImageItem currItem) async {
    if (_isAddingNext) {
      return;
    } else {
      _isAddingNext = true;
      final msg = await ChatMsgDao().getNextImageMsgAfterMid(
          currItem.chatMsgM.mid,
          uid: currItem.chatMsgM.dmUid,
          gid: currItem.chatMsgM.gid);
      if (msg != null) {
        final imageFile = await _getImageFile(msg);
        if (imageFile != null && mounted) {
          setState(() {
            _addToEnd(SingleImageItem(initImageFile: imageFile, chatMsgM: msg));
          });
        }
      }
      _isAddingNext = false;
    }
  }

  Future<File?> _getImageFile(ChatMsgM chatMsgM) async {
    return (await FileHandler.singleton.getImageNormal(chatMsgM)) ??
        (await FileHandler.singleton.getImageThumb(chatMsgM));
  }
}
