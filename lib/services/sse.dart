import 'dart:async';

import 'package:vocechat_client/app.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vocechat_client/app_consts.dart';

typedef SseEventAware = void Function(dynamic);

class Sse {
  static final Sse sse = Sse._internal();

  html.EventSource? eventSource;

  Sse._internal();

  final Set<SseEventAware> sseEventListeners = {};

  int reconnectSec = 1;

  bool isConnecting = false;

  Timer? _reconnectTimer;

  void connect() {
    if (isConnecting) return;

    isConnecting = true;

    close();
    App.logger.info("Connecting SSE: ${prepareUrl()}");
    App.app.statusService.fireSseLoading(LoadingStatus.loading);

    final eventSource = html.EventSource(Uri.parse(prepareUrl()).toString());

    try {
      eventSource.onMessage.listen((event) {
        App.app.statusService.fireSseLoading(LoadingStatus.success);
        App.logger.info(event.data);
        fireSseEvent(event.data);
        isConnecting = false;
      });

      eventSource.onOpen.listen((event) {
        App.app.statusService.fireSseLoading(LoadingStatus.success);
        reconnectSec = 1;
        cancelDelay();
        isConnecting = false;
      });

      eventSource.onError.listen((event) {
        App.app.statusService.fireSseLoading(LoadingStatus.disconnected);
        App.logger.severe(event);
        eventSource.close();
        handleError();
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

  String prepareUrl() {
    String url = App.app.chatServerM.fullUrl + "/api/user/events?";

    final afterMid = App.app.userDb!.maxMid;
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

  void handleError() async {
    _reconnectTimer = Timer(Duration(seconds: reconnectSec), () {
      connect();
      reconnectSec *= 2;
      if (reconnectSec >= 64) {
        reconnectSec = 64;
      }
    });
  }

  void cancelDelay() {
    _reconnectTimer?.cancel();
  }

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
    App.logger.info("SSE Closed.");
  }
}
