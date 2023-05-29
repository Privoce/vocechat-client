import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/empty_data_placeholder.dart';
import 'package:vocechat_client/ui/widgets/empty_content_placeholder.dart';

class VoceZoomImageBubble extends StatefulWidget {
  final Future<ImageGalleryData> Function() getImageList;
  final Future<File?> Function({Function(int, int)? onReceiveProgress})
      getInitImage;

  final bool _isReply;

  final double aspectRatio;

  VoceZoomImageBubble(
      {Key? key,
      required this.getInitImage,
      required this.getImageList,
      required this.aspectRatio})
      : _isReply = false,
        super(key: key);

  VoceZoomImageBubble.reply(
      {Key? key,
      required this.getInitImage,
      required this.getImageList,
      required this.aspectRatio})
      : _isReply = true,
        super(key: key);

  @override
  State<VoceZoomImageBubble> createState() => _VoceZoomImageBubbleState();
}

class _VoceZoomImageBubbleState extends State<VoceZoomImageBubble> {
  File? _imageFile;
  ValueNotifier<double> _progressNotifier = ValueNotifier(0);
  final ValueNotifier<DataLoadingStatus> _loadingStatus =
      ValueNotifier(DataLoadingStatus.init);

  @override
  void initState() {
    super.initState();
    _getInitImage();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = widget.aspectRatio > 1 ? 50 : 140;
        double width = widget.aspectRatio > 1
            ? constraints.maxWidth * 0.5
            : constraints.maxWidth * 0.3;
        BoxFit fit =
            widget.aspectRatio > 1 ? BoxFit.fitHeight : BoxFit.fitWidth;

        return SizedBox(
          height: height,
          width: width,
          child: _buildImage(fit),
        );
      },
    );
  }

  Widget _buildImage(BoxFit fit) {
    return ValueListenableBuilder<DataLoadingStatus>(
      valueListenable: _loadingStatus,
      builder: (context, status, child) {
        switch (status) {
          case DataLoadingStatus.loading:
            return Center(
              child: ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, progress, child) {
                  return CircularProgressIndicator(
                    value: progress,
                  );
                },
              ),
            );
          case DataLoadingStatus.success:
            return FittedBox(
              fit: fit,
              child: Image.file(_imageFile!),
            );
          default:
            return EmptyDataPlaceholder();
        }
      },
    );
  }

  Future<void> _getInitImage() async {
    _loadingStatus.value = DataLoadingStatus.loading;
    _imageFile =
        await widget.getInitImage(onReceiveProgress: onReceiveProgress);
    if (_imageFile == null) {
      _loadingStatus.value = DataLoadingStatus.notFound;
    } else {
      _loadingStatus.value = DataLoadingStatus.success;
    }
  }

  void onReceiveProgress(int progress, int total) {
    final p = progress / total;
    _progressNotifier.value = p;
  }
}

enum DataLoadingStatus { init, loading, success, notFound }
