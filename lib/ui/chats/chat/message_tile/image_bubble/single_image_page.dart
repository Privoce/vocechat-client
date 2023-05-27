import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/single_image_item.dart';

class SingleImagePage extends StatefulWidget {
  final File initImageFile;
  final SingleImageGetters singleImageGetters;
  final void Function(double)? onScaleChanged;

  const SingleImagePage(
      {Key? key,
      required this.initImageFile,
      required this.singleImageGetters,
      required this.onScaleChanged})
      : super(key: key);

  @override
  State<SingleImagePage> createState() => _SingleImagePageState();
}

class _SingleImagePageState extends State<SingleImagePage> {
  late ValueNotifier<File> _imageNotifier;
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);
  late bool _isOriginal;

  @override
  void initState() {
    super.initState();
    _initImageNotifier();
    _isOriginal = widget.singleImageGetters.isOriginal;

    if (widget.singleImageGetters.getServerImageFile != null) {
      widget.singleImageGetters.getServerImageFile!(_isOriginal, _imageNotifier,
          ((progress, total) {
        final p = progress / total;
        _progressNotifier.value = p;
      }));
    }
  }

  void _initImageNotifier() {
    _imageNotifier = ValueNotifier(widget.initImageFile);
  }

  @override
  Widget build(BuildContext context) {
    final child = ValueListenableBuilder<File>(
        valueListenable: _imageNotifier,
        builder: (context, imageFile, _) {
          return Center(
            child: PhotoView(imageProvider: FileImage(imageFile)),
          );
        });

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              child,
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
          )),
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
