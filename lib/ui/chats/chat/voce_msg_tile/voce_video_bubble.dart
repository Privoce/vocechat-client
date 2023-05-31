import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler/video_thumb_handler.dart';

class VoceVideoBubble extends StatefulWidget {
  final ChatMsgM chatMsgM;

  const VoceVideoBubble({required this.chatMsgM, super.key});

  @override
  State<VoceVideoBubble> createState() => _VoceVideoBubbleState();
}

class _VoceVideoBubbleState extends State<VoceVideoBubble> {
  File? _thumbFile;
  final ValueNotifier<VideoBubbleStatus> status =
      ValueNotifier(VideoBubbleStatus.ready);

  @override
  void initState() {
    super.initState();

    _fetchThumb();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LayoutBuilder(
        builder: (context, constrain) {
          final width = constrain.maxWidth * 0.8;
          final height = width * 2 / 3;
          final buttonSize = width * 0.2;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [_buildThumb(), _buildButton(buttonSize)],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumb() {
    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: _thumbFile != null
          ? Image.file(
              _thumbFile!,
              fit: BoxFit.fill,
            )
          : Container(
              color: Colors.grey,
            ),
    );
  }

  Widget _buildButton(double buttonSize) {
    return Center(
      child: ValueListenableBuilder<VideoBubbleStatus>(
        valueListenable: status,
        builder: (context, status, child) {
          switch (status) {
            case VideoBubbleStatus.ready:
              return CupertinoButton(
                padding: EdgeInsets.zero,
                color: Colors.white,
                borderRadius: BorderRadius.circular(buttonSize / 2),
                child: Icon(Icons.play_arrow,
                    color: Colors.grey, size: buttonSize),
                onPressed: () {},
              );
            case VideoBubbleStatus.loading:
              return CircularProgressIndicator();
            case VideoBubbleStatus.error:
              return IconButton(
                icon: Icon(Icons.error),
                onPressed: () {},
              );
          }
        },
      ),
    );
  }

  void _fetchThumb() async {
    final thumb = await VideoThumbHandler().readOrFetch(widget.chatMsgM);
    if (thumb != null) {
      setState(() {
        _thumbFile = thumb;
      });
    }
  }

  void _fetchFile() async {}
}

enum VideoBubbleStatus {
  /// initial status, file needs to be fetched or has been fetched and is ready
  /// to be played.
  ready,
  loading,
  error
}
