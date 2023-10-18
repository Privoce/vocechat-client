import 'dart:collection';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class EventQueue {
  final queue = Queue<dynamic>();

  final Future Function(dynamic sseMsg) closure;
  Future<dynamic> Function()? afterTaskCheck;
  bool enableStatusDisplay;

  EventQueue(
      {required this.closure,
      this.afterTaskCheck,
      this.enableStatusDisplay = true});

  bool isProcessing = false;

  void add(String sseMsg) {
    if (sseMsg.isNotEmpty) {
      queue.add(sseMsg);
      _process();
    }
  }

  Future<void> clear() async {
    queue.clear();
  }

  Future _process() async {
    if (!isProcessing) {
      isProcessing = true;
      if (enableStatusDisplay && queue.isNotEmpty) {
        App.app.statusService?.fireTaskLoading(LoadingStatus.loading);
      }

      await Future.doWhile(() async {
        try {
          dynamic topSseMsg = queue.removeFirst();
          await closure(topSseMsg);
        } catch (e) {
          App.logger.severe(e);
        }
        return queue.isNotEmpty;
      });

      isProcessing = false;

      if (afterTaskCheck != null) {
        await afterTaskCheck!();
      }

      if (enableStatusDisplay && queue.isEmpty) {
        App.app.statusService?.fireTaskLoading(LoadingStatus.success);
      }
    }
  }
}
