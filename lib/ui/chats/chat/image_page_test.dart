import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

class ImagePageTest extends StatefulWidget {
  final File initImageFile;
  final String localMid;
  final Future<File?> Function() getImage;

  ImagePageTest(
      {required this.initImageFile,
      required this.localMid,
      required this.getImage});

  @override
  State<ImagePageTest> createState() => _ImagePageTestState();
}

class _ImagePageTestState extends State<ImagePageTest> {
  late File imageFile;
  final ValueNotifier<bool> _isFetching = ValueNotifier(false);
  late NavigatorState _navigator;

  ValueNotifier<ButtonStatus> saveStatus = ValueNotifier(ButtonStatus.normal);

  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    imageFile = widget.initImageFile;

    _getImage();
  }

  @override
  void dispose() {
    // _navigator.pop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
      // bottomNavigationBar: _buildNavBarActions());
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        GestureDetector(
            onTap: () async {
              _navigator.pop();
            },
            child: Center(child: _buildImage())),
        Positioned(bottom: 50, right: 16, child: _buildNavBarActions()),
      ],
    );
  }

  Widget _buildNavBarActions() {
    return SizedBox(
      height: 48,
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        ValueListenableBuilder<ButtonStatus>(
            valueListenable: saveStatus,
            builder: (context, status, _) {
              return _buildNavBarButton(
                  icon: AppIcons.download,
                  size: 20,
                  status: status,
                  onPressed: (() {
                    _saveImage(imageFile);
                  }));
            }),
        _buildNavBarButton(
            icon: AppIcons.share,
            size: 24,
            status: ButtonStatus.normal,
            onPressed: (() {
              Share.shareFiles([imageFile.path]);
            }))
      ]),
    );
  }

  Widget _buildNavBarButton(
      {IconData? icon,
      required double size,
      VoidCallback? onPressed,
      required ButtonStatus status}) {
    Widget child;
    switch (status) {
      case ButtonStatus.normal:
        child = Icon(icon, color: Colors.white, size: size);
        break;
      case ButtonStatus.inProgress:
        child =
            CupertinoActivityIndicator(radius: size / 2, color: Colors.white);
        break;
      case ButtonStatus.success:
        child = Icon(Icons.check, color: Colors.white, size: size);
        break;
      case ButtonStatus.error:
        child = Icon(CupertinoIcons.exclamationmark,
            color: Colors.white, size: size);
        break;

      default:
        child = Icon(icon, color: Colors.white, size: size);
    }

    return CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: status == ButtonStatus.error
                    ? AppColors.errorRed
                    : AppColors.grey600,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey600.withOpacity(0.6),
                    spreadRadius: 5,
                    blurRadius: 5,
                  )
                ]),
            child: Center(child: child)),
        onPressed: status == ButtonStatus.normal ? onPressed : null);
  }

  Widget _buildImage() {
    return Stack(
      children: [
        PhotoView.customChild(
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          child: Hero(
              tag: widget.localMid,
              child: Image.file(imageFile, fit: BoxFit.contain)),
        ),
        ValueListenableBuilder<bool>(
            valueListenable: _isFetching,
            builder: (context, isFetching, _) {
              if (isFetching) {
                return Center(
                    child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.coolGrey700.withAlpha(200),
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.all(10),
                  child: CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 20,
                  ),
                ));
              }

              return SizedBox.shrink();
            }),
      ],
    );
  }

  Future<File?> _getImage() async {
    _isFetching.value = true;

    // A bit quicker than PageRoute transitionDuration (300 for FadePageRoute)
    await Future.delayed(Duration(milliseconds: 200));

    try {
      final imageFile = await widget.getImage();
      if (imageFile != null) {
        setState(() {
          this.imageFile = imageFile;
          _isFetching.value = false;
        });
        return imageFile;
      } else {
        _isFetching.value = false;
      }
    } catch (e) {
      App.logger.severe(e);
      _isFetching.value = false;
    }
    return null;
  }

  void _saveImage(File imageFile) async {
    saveStatus.value = ButtonStatus.inProgress;
    try {
      final result = await ImageGallerySaver.saveFile(imageFile.path);
      if (result["isSuccess"]) {
        saveStatus.value = ButtonStatus.success;
        await Future.delayed(Duration(seconds: 2)).then((_) async {
          saveStatus.value = ButtonStatus.normal;
        });
      }
    } catch (e) {
      App.logger.severe(e);
      saveStatus.value = ButtonStatus.error;
      await Future.delayed(Duration(seconds: 2)).then((_) async {
        saveStatus.value = ButtonStatus.normal;
      });
    }
    saveStatus.value = ButtonStatus.normal;
  }
}

enum ButtonStatus { normal, inProgress, success, error }
