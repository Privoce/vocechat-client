import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class VideoPage extends StatefulWidget {
  final ChewieController chewieController;

  VideoPage(this.chewieController);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.chewieController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        centerTitle: true,
      ),
      body: widget.chewieController.videoPlayerController.value.isInitialized
          ? SafeArea(child: Chewie(controller: widget.chewieController))
          : Center(child: CupertinoActivityIndicator()),
    );
  }

  // void _initControllers() async {
  //   _videoPlayerController = VideoPlayerController.file(widget.file);
  //   await _videoPlayerController.initialize();

  //   _chewieController = ChewieController(
  //       videoPlayerController: _videoPlayerController,
  //       autoPlay: false,
  //       looping: false);
  // }
}
