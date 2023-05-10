import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/models/ui_models/audio_info.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/audio/voce_audio_progress_bar.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/empty_data_placeholder.dart';

class VoceAudioBubble extends StatefulWidget {
  final MsgTileData? tileData;

  final AudioInfo? audioInfo;

  final bool isSelf;

  final double? height;

  VoceAudioBubble.tileData(
      {Key? key, required MsgTileData this.tileData, this.isSelf = false})
      : height = null,
        audioInfo = tileData.audioInfo,
        super(key: key);

  const VoceAudioBubble.data(
      {Key? key, this.audioInfo, this.isSelf = false, this.height = 36})
      : tileData = null,
        super(key: key);

  @override
  State<VoceAudioBubble> createState() => _VoceAudioBubbleState();
}

class _VoceAudioBubbleState extends State<VoceAudioBubble>
    with SingleTickerProviderStateMixin {
  AudioInfo? audioInfo;

  @override
  initState() {
    super.initState();

    if (widget.tileData != null && widget.tileData!.needServerPrepare) {
      widget.tileData!.serverPrepare().then((value) {
        setState(() {
          audioInfo = widget.tileData!.audioInfo;
        });
      });
    } else {
      audioInfo = widget.audioInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (audioInfo != null) {
      return FractionallySizedBox(
        widthFactor: calAudioBubbleWidthFactor(audioInfo!.duration),
        child: VoceProgressBar(
          player: audioInfo!.player,
          duration: audioInfo!.duration,
          textAlignment: getTextAlignment(),
          height: widget.height ?? 36,
        ),
      );
    } else {
      return const EmptyDataPlaceholder();
    }
  }

  double calAudioBubbleWidthFactor(int millisecs) {
    double factor = millisecs / 30000;
    if (factor < 0.3) {
      return 0.3;
    } else if (factor > 1) {
      return 1;
    } else {
      return factor;
    }
  }

  AlignmentGeometry getTextAlignment() {
    if (widget.tileData != null && widget.isSelf) {
      return Alignment.centerRight;
    }
    return Alignment.centerLeft;
  }
}
