import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/chat_image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_page.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({Key? key, required this.data}) : super(key: key);

  final ImageGalleryData data;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final PageController _controller;
  late final List<SingleImageItem> _imageList;

  @override
  void initState() {
    super.initState();

    _initController();
    _imageList = widget.data.imageItemList;
  }

  void _initController() {
    _controller =
        PageController(keepPage: true, initialPage: widget.data.initialPage);
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
          itemBuilder: _buildItem,
        ));
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _imageList[index];

    return Builder(builder: (context) {
      return FutureBuilder<_SingleImageData?>(
          future: _getImageFileData(item.chatMsgM),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return SingleImagePage(
                  initImageFile: snapshot.data!.imageFile,
                  chatMsgM: item.chatMsgM,
                  isOriginal: snapshot.data!.isOriginal);
            } else {
              return Center(child: Text("cant find file"));
            }
          });
    });
    // }
  }

  Future<_SingleImageData?> _getImageFileData(ChatMsgM chatMsgM) async {
    final localImageNormal =
        await FileHandler.singleton.getLocalImageNormal(chatMsgM);
    if (localImageNormal != null) {
      return _SingleImageData(imageFile: localImageNormal, isOriginal: true);
    } else {
      final localImageThumb =
          await FileHandler.singleton.getLocalImageThumb(chatMsgM);
      if (localImageThumb != null) {
        return _SingleImageData(imageFile: localImageThumb, isOriginal: false);
      }
    }
    return null;
  }
}

class _SingleImageData {
  final bool isOriginal;
  final File imageFile;

  _SingleImageData({required this.imageFile, required this.isOriginal});
}
