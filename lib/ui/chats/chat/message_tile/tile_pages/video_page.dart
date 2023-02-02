import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/mixins/orientation_mixins.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class VideoPage extends StatefulWidget {
  final ChewieController chewieController;

  VideoPage(this.chewieController);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
// with PortraitStatefulModeMixin<VideoPage>
{
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.chewieController.pause();
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
}
