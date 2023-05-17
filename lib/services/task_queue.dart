import 'dart:async';

import 'package:vocechat_client/app.dart';

class _QueuedFuture {
  final Completer completer;
  final Future Function() closure;

  _QueuedFuture(this.closure, this.completer);

  Future execute() async {
    try {
      final result = await closure()
          .catchError(completer.completeError)
          .then((value) async {});
      completer.complete(result);
      //Make sure not to execute the next commpand until this future has completed
      await Future.microtask(() {});
    } catch (e) {
      completer.completeError(e);
    }
  }
}

class TaskQueue {
  List<_QueuedFuture> nextCycle = [];
  List<_QueuedFuture> currentCycle = [];
  Duration? delay;
  bool isProcessing = false;
  bool isCancelled = false;
  Future<dynamic> Function()? afterTaskCheck;

  bool enableStatusDisplay;

  void cancel() {
    nextCycle.clear();
    currentCycle.clear();
    isCancelled = true;
  }

  void dispose() {
    cancel();
  }

  TaskQueue({this.delay, this.enableStatusDisplay = true, this.afterTaskCheck});

  Future add(Future Function() closure) {
    final completer = Completer();
    nextCycle.add(_QueuedFuture(closure, completer));
    unawaited(process());
    return completer.future;
  }

  Future<void> process() async {
    if (!isProcessing) {
      isProcessing = true;

      currentCycle = nextCycle;
      nextCycle = [];
      for (final _QueuedFuture item in currentCycle) {
        try {
          // if (enableStatusDisplay) {
          //   App.app.statusService?.fireTaskLoading(LoadingStatus.loading);
          // }
          await item.execute();
          if (delay != null) await Future.delayed(delay!);
        } catch (e) {
          App.logger.severe("error processing $e");
        }
      }
      isProcessing = false;

      // if (enableStatusDisplay) {
      //   App.app.statusService?.fireTaskLoading(LoadingStatus.success);
      // }

      if (afterTaskCheck != null) {
        await afterTaskCheck!();
      }

      if (isCancelled == false && nextCycle.isNotEmpty) {
        await Future.microtask(() {}); //Yield to prevent stack overflow
        unawaited(process());
      }
    }
  }
}

// Don't throw analysis error on unawaited future.
void unawaited(Future<void> future) {}
