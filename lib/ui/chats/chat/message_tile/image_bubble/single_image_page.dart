import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_share_sheet.dart';

class SingleImagePage extends StatefulWidget {
  final File initImageFile;
  final ChatMsgM chatMsgM;
  final bool isOriginal;
  final void Function(double)? onScaleChanged;

  const SingleImagePage(
      {Key? key,
      required this.initImageFile,
      required this.chatMsgM,
      required this.isOriginal,
      required this.onScaleChanged})
      : super(key: key);

  @override
  State<SingleImagePage> createState() => _SingleImagePageState();
}

class _SingleImagePageState extends State<SingleImagePage>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<File> _imageNotifier;
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);
  late bool _isOriginal;

  // For zoom in and out.
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails _doubleTapDetails = TapDownDetails();
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  final _zoomInMaxScale = 3.0;
  final _zoomDuration = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _initImageNotifier();
    _initAnimationController();
    _isOriginal = widget.isOriginal;

    _getServerImageFile(widget.chatMsgM);
  }

  void _initImageNotifier() {
    _imageNotifier = ValueNotifier(widget.initImageFile);
  }

  void _initAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: _zoomDuration,
    )..addListener(() {
        _transformationController.value = _animation.value;
      });
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    Matrix4 endMatrix;
    Offset position = _doubleTapDetails.localPosition;

    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(_zoomInMaxScale);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurveTween(curve: Curves.decelerate).animate(_animationController),
    );
    _animationController.forward(from: 0);
  }

  void _onLongPress(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ImageShareSheet(chatMsgM: widget.chatMsgM);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = ValueListenableBuilder<File>(
        valueListenable: _imageNotifier,
        builder: (context, imageFile, _) {
          return Stack(
            children: [
              Center(
                  child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
              )),
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, value, child) {
                  if (value < 0.05 || value >= 1) {
                    return const SizedBox.shrink();
                  } else {
                    return Center(
                        child: CircularProgressIndicator(value: value));
                  }
                },
              )
            ],
          );
        });

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      onDoubleTap: _onDoubleTap,
      onDoubleTapDown: _onDoubleTapDown,

      // onLongPress: () => _onLongPress(context),
      child: Container(
          color: Colors.black,
          child: InteractiveViewer(
              maxScale: _zoomInMaxScale,
              panEnabled: true,
              // boundaryMargin: EdgeInsets.all(double.infinity),
              transformationController: _transformationController,
              onInteractionEnd: (details) {
                double scale =
                    _transformationController.value.getMaxScaleOnAxis();

                if (widget.onScaleChanged != null) {
                  widget.onScaleChanged!(scale);
                }
              },
              child: child)),
    );
  }

  Future<File?> _getServerImageFile(ChatMsgM chatMsgM) async {
    if (_isOriginal) {
      return null;
    }

    final serverImageNormal = await FileHandler.singleton.getServerImageNormal(
      chatMsgM,
      onReceiveProgress: (progress, total) {
        _progressNotifier.value = progress / total;
      },
    );
    if (serverImageNormal != null) {
      _imageNotifier.value = serverImageNormal;
      _isOriginal = true;
      return serverImageNormal;
    } else {
      final serverImageThumb = await FileHandler.singleton.getServerImageThumb(
        chatMsgM,
        onReceiveProgress: (progress, total) {
          _progressNotifier.value = progress / total;
        },
      );
      if (serverImageThumb != null) {
        _imageNotifier.value = serverImageThumb;
        _isOriginal = false;
        return serverImageThumb;
      }
    }
    return null;
  }

  /// Keep this function for future refactor.
  Future<File?> _getOriginalImage(ChatMsgM chatMsgM) async {
    if (_isOriginal) return null;

    final serverImageNormal = await FileHandler.singleton.getServerImageNormal(
      chatMsgM,
      onReceiveProgress: (progress, total) {
        _progressNotifier.value = progress / total;
      },
    );
    if (serverImageNormal != null) {
      _imageNotifier.value = serverImageNormal;
      _isOriginal = true;
      return serverImageNormal;
    }
    return null;
  }
}
