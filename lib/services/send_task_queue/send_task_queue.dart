import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class SendTaskQueue {
  static final SendTaskQueue singleton = SendTaskQueue._instance();
  factory SendTaskQueue() {
    return singleton;
  }
  SendTaskQueue._instance();

  final Queue<SendTask> _sendTaskQueue = Queue();
  bool isProcessing = false;

  void addTask(SendTask task) {
    _sendTaskQueue.add(task);
    _process();
  }

  Future _process() async {
    if (!isProcessing) {
      isProcessing = true;

      await Future.doWhile(() async {
        SendTask topTask = _sendTaskQueue.removeFirst();
        _sendTaskQueue.addFirst(topTask..status.value = MsgSendStatus.sending);

        try {
          await topTask.sendTask();
        } catch (e) {
          App.logger.severe(e);
        }
        _sendTaskQueue.removeFirst();

        return _sendTaskQueue.isNotEmpty;
      });

      isProcessing = false;
    }
  }

  SendTask? getTask(String localMid) {
    try {
      return _sendTaskQueue
          .firstWhere((element) => element.localMid == localMid);
    } catch (e) {
      // App.logger.warning(e);
      return null;
    }
  }

  bool isWaitingOrExecuting(String localMid) {
    return _sendTaskQueue.map((e) => e.localMid).contains(localMid);
  }
}

class SendTask {
  final String localMid;
  final Future<bool> Function() sendTask;
  ValueNotifier<MsgSendStatus> status =
      ValueNotifier(MsgSendStatus.readyToSend);
  ValueNotifier<double>? progress = ValueNotifier(0);

  SendTask({required this.localMid, required this.sendTask});
}
