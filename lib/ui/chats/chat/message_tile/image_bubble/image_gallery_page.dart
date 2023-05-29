import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_share_sheet.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_page.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({Key? key, required this.data}) : super(key: key);

  final ImageGalleryData data;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage>
// with LandscapeStatefulModeMixin<ImageGalleryPage>
{
  late final PageController _controller;
  late final List<SingleImageGetters> _imageList;

  late final ValueNotifier<bool> _showButtons;
  final ValueNotifier<ButtonStatus> _saveBtnStatus =
      ValueNotifier(ButtonStatus.normal);

  bool _enablePageView = true;

  @override
  void initState() {
    super.initState();

    _initController();

    _showButtons = ValueNotifier(true);
    _imageList = widget.data.imageItemList;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initController() {
    _controller =
        PageController(keepPage: true, initialPage: widget.data.initialPage);

    _controller.addListener(() {
      final decimal = _controller.page! - _controller.page!.truncate();

      _showButtons.value = decimal <= 0.5 || decimal >= 0.95;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: Stack(
          children: [
            GestureDetector(
              onLongPress: _share,
              child: PageView.builder(
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
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showButtons,
              builder: (context, showButtons, child) {
                if (showButtons) {
                  return _buildButtons();
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ],
        ));
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _imageList[index];

    return FutureBuilder<SingleImageData?>(
        future: item.getLocalImageFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data != null) {
            return SingleImagePage(
              initImageFile: snapshot.data!.imageFile,
              singleImageGetters: item,
              onScaleChanged: (scale) {
                setState(() {
                  _enablePageView = scale <= 1.0;
                });
              },
            );
          } else {
            return Center(
                child: Container(
                    color: Colors.amber, child: Text("cant find file")));
          }
        });
  }

  Widget _buildButtons() {
    return Positioned(
      bottom: 36,
      right: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildShareButton(), SizedBox(width: 8), _buildSaveButton()],
      ),
    );
  }

  Widget _buildShareButton() {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _share,
        child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.grey600,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
                child: Icon(AppIcons.share, size: 20, color: Colors.white))));
  }

  void _share() async {
    final index = _controller.page?.round() ?? widget.data.initialPage;

    final singleImageData = await _imageList[index].getLocalImageFile();

    if (singleImageData == null) return;

    showModalBottomSheet(
        context: navigatorKey.currentContext!,
        isScrollControlled: true,
        builder: (context) {
          return ImageShareSheet(imageFile: singleImageData.imageFile);
        });
  }

  Widget _buildSaveButton() {
    return ValueListenableBuilder<ButtonStatus>(
      valueListenable: _saveBtnStatus,
      builder: (context, status, child) {
        Widget child;
        double size = 20;

        switch (status) {
          case ButtonStatus.normal:
            child = Icon(Icons.save_alt, color: Colors.white, size: size);
            break;
          case ButtonStatus.inProgress:
            child = CupertinoActivityIndicator(
                radius: size / 2, color: Colors.white);
            break;
          case ButtonStatus.success:
            child = Icon(Icons.check, color: Colors.white, size: size);
            break;
          case ButtonStatus.error:
            child = Icon(CupertinoIcons.exclamationmark,
                color: Colors.white, size: size);
            break;

          default:
            child = Icon(Icons.save_alt, color: Colors.white, size: size);
        }

        return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: status == ButtonStatus.normal ? _saveImage : null,
            child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: status == ButtonStatus.error
                      ? AppColors.errorRed
                      : AppColors.grey600,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(child: child)));
      },
    );
  }

  void _saveImage() async {
    _saveBtnStatus.value = ButtonStatus.inProgress;

    try {
      final index = _controller.page?.round() ?? widget.data.initialPage;
      final singleImageData = await _imageList[index].getLocalImageFile();

      if (singleImageData?.imageFile == null) {
        _saveBtnStatus.value = ButtonStatus.error;
        await Future.delayed(Duration(seconds: 2)).then((_) async {
          _saveBtnStatus.value = ButtonStatus.normal;
        });
        return;
      }

      final image = singleImageData!.imageFile;
      final name = image.path.split("/").last;
      final imageBytes = await image.readAsBytes();

      final result = await SaverGallery.saveImage(imageBytes,
          name: name, androidExistNotSave: false);

      if (result.isSuccess) {
        _saveBtnStatus.value = ButtonStatus.success;
        await Future.delayed(Duration(seconds: 2)).then((_) async {
          _saveBtnStatus.value = ButtonStatus.normal;
        });
      }
    } catch (e) {
      App.logger.severe(e);
      _saveBtnStatus.value = ButtonStatus.error;
      await Future.delayed(Duration(seconds: 2)).then((_) async {
        _saveBtnStatus.value = ButtonStatus.normal;
      });
    }
    _saveBtnStatus.value = ButtonStatus.normal;
  }
}

class SingleImageData {
  final bool isOriginal;
  final File imageFile;

  SingleImageData({required this.imageFile, required this.isOriginal});
}
