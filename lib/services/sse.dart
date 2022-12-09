import 'dart:async';
import 'dart:convert';

import 'package:universal_html/html.dart';
import 'package:vocechat_client/app.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/sse_event/sse_event_consts.dart';

typedef SseEventAware = void Function(dynamic);

class Sse {
  static final Sse sse = Sse._internal();

  html.EventSource? eventSource;

  Sse._internal();

  final Set<SseEventAware> sseEventListeners = {};

  int reconnectSec = 1;

  bool isConnecting = false;

  Timer? _reconnectTimer;

  /// shows whether sse has received 'ready' message from server.
  bool _afterReady = false;

  bool get afterReady => _afterReady;

  void connect() async {
    if (isConnecting) return;

    isConnecting = true;

    close();
    App.logger.info("Connecting SSE: ${await prepareUrl()}");
    App.app.statusService.fireSseLoading(SseStatus.connecting);

    final eventSource =
        html.EventSource(Uri.parse(await prepareUrl()).toString());

    try {
      eventSource.onMessage.listen((event) {
        App.app.statusService.fireSseLoading(SseStatus.successful);
        App.logger.info(event.data);
        fireSseEvent(event.data);

        isConnecting = false;
      });

      eventSource.onOpen.listen((event) {
        App.app.statusService.fireSseLoading(SseStatus.successful);
        reconnectSec = 1;
        cancelReconnectionDelay();

        isConnecting = false;
      });

      eventSource.onError.listen((event) {
        App.app.statusService.fireSseLoading(SseStatus.disconnected);
        App.logger.severe(event);
        eventSource.close();
        handleError(event);

        isConnecting = false;
      });
    } catch (e) {
      App.logger.severe(e);
    }

    this.eventSource = eventSource;
  }

  void subscribeSseEvent(SseEventAware aware) {
    // unsubscribeSseEvent(aware);
    unsubscribeAllSseEvents();
    sseEventListeners.add(aware);
  }

  void unsubscribeSseEvent(SseEventAware aware) {
    sseEventListeners.remove(aware);
  }

  void unsubscribeAllSseEvents() {
    sseEventListeners.clear();
  }

  void fireSseEvent(dynamic event) {
    for (SseEventAware sseEventAware in sseEventListeners) {
      try {
      sseEventAware(event);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  Future<String> prepareUrl() async {
    String url = App.app.chatServerM.fullUrl + "/api/user/events?";

    final afterMid = await ChatMsgDao().getMaxMid();
    if (afterMid > -1) {
      url += "after_mid=$afterMid";
    }

    final usersVersion = App.app.userDb!.usersVersion;
    if (usersVersion > 0) {
      url += "&users_version=$usersVersion";
    }

    url += "&api-key=${App.app.userDb!.token}";

    return url;
  }

  void handleError(Event event) async {
    _reconnectTimer = Timer(Duration(seconds: reconnectSec), () {
      connect();
      reconnectSec *= 2;
      if (reconnectSec >= 64) {
        reconnectSec = 64;
      }
    });
  }

  void cancelReconnectionDelay() {
    _reconnectTimer?.cancel();
  }

  // void _setAfterReady() {
  //   _afterReady = true;
  // }

  // void _resetAfterReady() {
  //   _afterReady = false;
  // }

  // void _monitorReadyEvent(dynamic event) {
  //   final map = json.decode(event);
  //   final type = map["type"];
  //   if (type == sseReady) _setAfterReady();
  // }

  bool isClosed() {
    if (eventSource == null) {
      eventSource = null;
      return true;
    }
    return eventSource?.readyState == html.EventSource.CLOSED;
  }

  void close() {
    eventSource?.close();
    eventSource = null;
    isConnecting = false;
    _reconnectTimer?.cancel();
    App.logger.info("SSE Closed.");
  }
}
