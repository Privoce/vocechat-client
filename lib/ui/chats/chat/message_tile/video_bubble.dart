import 'dart:core';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler.dart';

class VideoBubble extends StatefulWidget {
  final ChatMsgM chatMsgM;
  final Future<File?> Function(Function(int, int)) getVideoFile;

  VideoBubble({required this.chatMsgM, required this.getVideoFile});

  @override
  State<VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<VideoBubble> {
  late Widget thumb;

  @override
  void initState() {
    super.initState();
    getThumbFile(widget.chatMsgM);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [thumb, Icon(Icons.play_circle_fill)],
        ),
        onPressed: () {});
  }

  void getThumbFile(ChatMsgM chatMsgM) async {
    thumb =
        SvgPicture.asset("assets/images/file_video.svg", width: 60, height: 80);

    final thumbFile = await FileHandler().getVideoThumb(chatMsgM);
    if (thumbFile != null) {
      setState(() {
        thumb = Image.file(thumbFile);
      });
    }
  }
}
