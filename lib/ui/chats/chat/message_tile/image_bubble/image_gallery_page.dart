import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
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

  late final ValueNotifier<bool> _showButtons;
  final ValueNotifier<_ButtonStatus> _saveBtnStatus =
      ValueNotifier(_ButtonStatus.normal);

  bool _enablePageView = true;

  @override
  void initState() {
    super.initState();

    _initController();

    _showButtons = ValueNotifier(true);
    _imageList = widget.data.imageItemList;
  }

  void _initController() {
    _controller =
        PageController(keepPage: true, initialPage: widget.data.initialPage);

    _controller.addListener(() {
      final decimal = _controller.page! - _controller.page!.truncate();

      _showButtons.value = decimal == 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              allowImplicitScrolling: true,
              itemCount: _imageList.length,
              physics: _enablePageView
                  ? (Platform.isIOS
                      ? BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics())
                      : AlwaysScrollableScrollPhysics())
                  : const NeverScrollableScrollPhysics(),
              itemBuilder: _buildItem,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showButtons,
              builder: (context, showButtons, child) {
                if (showButtons) {
                  final index =
                      _controller.page?.round() ?? widget.data.initialPage;

                  return Text(
                    "buttons",
                    style: TextStyle(color: Colors.white),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
            _buildButtons()
          ],
        ));
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _imageList[index];

    return FutureBuilder<_SingleImageData?>(
        future: _getLocalImageFileData(item.chatMsgM),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return SingleImagePage(
              initImageFile: snapshot.data!.imageFile,
              chatMsgM: item.chatMsgM,
              isOriginal: snapshot.data!.isOriginal,
              onScaleChanged: (scale) {
                setState(() {
                  _enablePageView = scale <= 1.0;
                });
              },
            );
          } else {
            return Center(child: Text("cant find file"));
          }
        });

    // }
  }

  Future<_SingleImageData?> _getLocalImageFileData(ChatMsgM chatMsgM) async {
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

  Widget _buildButtons() {
    return Positioned(
      bottom: 36,
      right: 16,
      child: Row(
        children: [_buildDownloadButton()],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return ValueListenableBuilder<_ButtonStatus>(
      valueListenable: _saveBtnStatus,
      builder: (context, status, child) {
        Widget child;
        double size = 16;

        switch (status) {
          case _ButtonStatus.normal:
            child = Icon(AppIcons.download, color: Colors.white, size: size);
            break;
          case _ButtonStatus.inProgress:
            child = CupertinoActivityIndicator(
                radius: size / 2, color: Colors.white);
            break;
          case _ButtonStatus.success:
            child = Icon(Icons.check, color: Colors.white, size: size);
            break;
          case _ButtonStatus.error:
            child = Icon(CupertinoIcons.exclamationmark,
                color: Colors.white, size: size);
            break;

          default:
            child = Icon(AppIcons.download, color: Colors.white, size: size);
        }

        return CupertinoButton(
            child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: status == _ButtonStatus.error
                      ? AppColors.errorRed
                      : AppColors.grey600,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(child: child)),
            onPressed: status == _ButtonStatus.normal ? _saveImage : null);
      },
    );
  }

  void _saveImage() async {
    _saveBtnStatus.value = _ButtonStatus.inProgress;

    try {
      final index = _controller.page?.round() ?? widget.data.initialPage;

      final imageFile =
          (await _getLocalImageFileData(_imageList[index].chatMsgM))?.imageFile;

      if (imageFile == null) {
        _saveBtnStatus.value = _ButtonStatus.error;
        await Future.delayed(Duration(seconds: 2)).then((_) async {
          _saveBtnStatus.value = _ButtonStatus.normal;
        });
        return;
      }

      final result = await ImageGallerySaver.saveFile(imageFile.path);
      if (result["isSuccess"]) {
        _saveBtnStatus.value = _ButtonStatus.success;
        await Future.delayed(Duration(seconds: 2)).then((_) async {
          _saveBtnStatus.value = _ButtonStatus.normal;
        });
      }
    } catch (e) {
      App.logger.severe(e);
      _saveBtnStatus.value = _ButtonStatus.error;
      await Future.delayed(Duration(seconds: 2)).then((_) async {
        _saveBtnStatus.value = _ButtonStatus.normal;
      });
    }
    _saveBtnStatus.value = _ButtonStatus.normal;
  }
}

enum _ButtonStatus { normal, inProgress, success, error }

class _SingleImageData {
  final bool isOriginal;
  final File imageFile;

  _SingleImageData({required this.imageFile, required this.isOriginal});
}
