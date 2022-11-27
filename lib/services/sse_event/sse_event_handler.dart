import 'dart:convert';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/services/sse.dart';

/// Handle and distribute SSE messages
///
/// It treats SSE initial messages differently to normal sse messages.
class SseEventHandler {
  SseEventHandler();

  /// Show whether sse receives 'Ready' message.
  /// False by default. Will be changed to true after 'Ready' has been received.
  bool _afterReady = false;

  List<dynamic> _preReadyEvents = [];

  void resetReadyState() {
    _afterReady = false;
  }

  void setReadyState() {
    _afterReady = true;
  }

  void init() {
    resetReadyState();
    Sse.sse.subscribeSseEvent(_handleSseEvent);
  }

  void _handleSseEvent(dynamic event) {
    try {
      final map = json.decode(event) as Map<String, dynamic>;
      final type = map["type"];

      if (type == "ready") {
        setReadyState();

        // TODO: fire accumulated messages to chat service.
      }

      if (_afterReady) {
        // TODO: fire to chat service.
      } else {
        _accumulatePreReadyEvents(event);
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void _accumulatePreReadyEvents(dynamic event) {
    _preReadyEvents.add(event);
  }

  void _resetPreReadyEvents() {
    _preReadyEvents = [];
  }

  void _firePreReadyMsgs(List<dynamic> msgs) {}
}
