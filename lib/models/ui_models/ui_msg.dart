import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/send_task_queue/send_task_queue.dart';

class UiMsg {
  ChatMsgM chatMsgM;
  ValueNotifier<MsgSendStatus> status = ValueNotifier(MsgSendStatus.success);
  File? file;
  Archive? archive;

  ChatMsgM? repliedMsgM;
  UserInfoM? repliedUserInfoM;
  File? repliedThumbFile;

  // Timer? _autoDeletionTimer;
  // ValueNotifier<int>? _autoDeletionCountDown;

  UiMsg(
      {required this.chatMsgM,
      // required this.status,
      this.file,
      this.archive,
      this.repliedMsgM,
      this.repliedUserInfoM,
      this.repliedThumbFile}) {
    status.value =
        SendTaskQueue.singleton.isWaitingOrExecuting(chatMsgM.localMid)
            ? MsgSendStatus.sending
            : getMsgSendStatus(chatMsgM.status);

    // Set auto deletion.
  }

  // // Includes pure text and markdown messages.
  // UiMsg.text({required this.chatMsgM})
  //     : file = null,
  //       archive = null,
  //       repliedMsgM = null,
  //       repliedUserInfoM = null,
  //       repliedThumbFile = null;

  // UiMsg.textWithTextReply(
  //     {required this.chatMsgM, this.repliedMsgM, this.repliedUserInfoM})
  //     : archive = null,
  //       repliedThumbFile = null;

  // // UiMsg.textWithImageReply()

  // // Includes image and corresponding chatMsgM
  // UiMsg.image({required this.chatMsgM, this.file})
  //     : archive = null,
  //       repliedMsgM = null,
  //       repliedThumbFile = null;
}
