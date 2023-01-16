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

  @override
  void initState() {
    super.initState();

    _initialize(widget.initImageItem);

    // _loadFrontBackImages(widget.initImageItem);
  }

  void _initController() {
    _controller = PageController(keepPage: true);

    _controller.addListener(() {
      final currentIndex = _controller.page!.round();
      SingleImageItem currItem = _imageList[_controller.page!.round()];
      print("listener _currentIndex: $currentIndex");
      if (currentIndex == 0) {
        _loadPreImages(currItem);
      }

      if (currentIndex == _imageList.length) {
        _loadNextImages(currItem);
      }

      // setState(() {});
    });
  }

  void _addToFront(SingleImageItem item) {
    if (!_imageLocalMidSet.contains(item.chatMsgM.localMid)) {
      _imageLocalMidSet.add(item.chatMsgM.localMid);
      _imageList.insert(0, item);

      // _imageList.sort(((a, b) => a.chatMsgM.mid.compareTo(b.chatMsgM.mid)));
    }
  }

  void _addToEnd(SingleImageItem item) {
    if (!_imageLocalMidSet.contains(item.chatMsgM.localMid)) {
      _imageLocalMidSet.add(item.chatMsgM.localMid);
      _imageList.add(item);

      // _imageList.sort(((a, b) => a.chatMsgM.mid.compareTo(b.chatMsgM.mid)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: PageView.builder(
          controller: _controller,
          // allowImplicitScrolling: true,
          itemCount: _imageList.length,
          physics: Platform.isIOS
              ? BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
              : AlwaysScrollableScrollPhysics(),
          itemBuilder: _buildItem,
        ));
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _imageList[index];
    print("builder index $index");
    // print("length: ${_imageList.length}");

    return SingleImagePage(
        initImageFile: item.initImageFile,
        loadOriginalImageFileCallBack: ((progressIndicator) {}));
  }

  void _initialize(SingleImageItem currItem) async {
    _initController();

    await _loadPreImages(currItem);
    await _loadNextImages(currItem);
  }

  Future<void> _loadPreImages(SingleImageItem currItem) async {
    final preMsg = await ChatMsgDao().getPreImageMsgBeforeMid(
        currItem.chatMsgM.mid,
        uid: currItem.chatMsgM.dmUid,
        gid: currItem.chatMsgM.gid);
    if (preMsg != null) {
      final imageFile = await _getImageFile(preMsg);
      if (imageFile != null && mounted) {
        print("currMid: ${currItem.chatMsgM.mid}, preMid: ${preMsg.mid}");
        setState(() {
          _addToFront(
              SingleImageItem(initImageFile: imageFile, chatMsgM: preMsg));
          // _controller.jumpToPage(_controller.page!.round() + 1);
          // _currentIndex += 1;
        });
      }
    }
  }

  Future<void> _loadNextImages(SingleImageItem currItem) async {
    final nextMsg = await ChatMsgDao().getNextImageMsgAfterMid(
        currItem.chatMsgM.mid,
        uid: currItem.chatMsgM.dmUid,
        gid: currItem.chatMsgM.gid);
    if (nextMsg != null) {
      final imageFile = await _getImageFile(nextMsg);
      if (imageFile != null && mounted) {
        setState(() {
          _addToEnd(
              SingleImageItem(initImageFile: imageFile, chatMsgM: nextMsg));
        });
      }
    }
  }

  Future<File?> _getImageFile(ChatMsgM chatMsgM) async {
    return (await FileHandler.singleton.getImageNormal(chatMsgM)) ??
        (await FileHandler.singleton.getImageThumb(chatMsgM));
  }
}
