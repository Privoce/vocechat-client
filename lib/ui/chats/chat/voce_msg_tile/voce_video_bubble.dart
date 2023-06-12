import 'dart:io';
import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_handler/video_thumb_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/tile_pages/video_page.dart';

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
  final ValueNotifier<double> progress = ValueNotifier(0);

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
          ? ValueListenableBuilder<VideoBubbleStatus>(
              valueListenable: status,
              builder: (context, status, child) {
                if (status == VideoBubbleStatus.loading) {
                  return Stack(
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: child,
                      ),
                      Container(color: Colors.white.withOpacity(0.6))
                    ],
                  );
                } else {
                  return child!;
                }
              },
              child: Container(
                color: Colors.black,
                child: Image.file(
                  width: double.maxFinite,
                  height: double.maxFinite,
                  _thumbFile!,
                  fit: BoxFit.contain,
                ),
              ),
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
                onPressed: _fetchFile,
                child: Icon(Icons.play_arrow,
                    color: Colors.grey, size: buttonSize),
              );
            case VideoBubbleStatus.loading:
              return ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, p, _) {
                  final progress = p < 0.1 ? 0.1 : p;
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(
                      value: progress,
                    ),
                  );
                },
              );
            case VideoBubbleStatus.error:
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    color: Colors.white),
                child: Icon(Icons.error_outline,
                    size: buttonSize / 1.2, color: AppColors.errorRed),
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

  void _fetchFile() async {
    try {
      File? file = await FileHandler.singleton.getLocalFile(widget.chatMsgM);

      if (file == null) {
        status.value = VideoBubbleStatus.loading;
        progress.value = 0;
        file = await FileHandler.singleton.getFile(widget.chatMsgM,
            (progress, total) {
          this.progress.value = progress / total;
        });
      }

      if (file == null) {
        status.value = VideoBubbleStatus.error;
      }

      _pushToVideoPage(file);
    } catch (e) {
      App.logger.severe(e);
    }
    status.value = VideoBubbleStatus.ready;
  }

  void _pushToVideoPage(File? file) async {
    if (file == null) {
      return;
    }

    final VideoPlayerController videoPlayerController =
        VideoPlayerController.file(file);
    await videoPlayerController.initialize().then((value) {
      final ChewieController chewieController = ChewieController(
          videoPlayerController: videoPlayerController,
          autoPlay: true,
          looping: false);

      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VideoPage(chewieController, file)));
    });
  }
}

enum VideoBubbleStatus {
  /// initial status, file needs to be fetched or has been fetched and is ready
  /// to be played.
  ready,
  loading,
  error
}
