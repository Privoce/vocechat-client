import 'dart:async';
import 'dart:convert';

import 'package:universal_html/html.dart';
import 'package:vocechat_client/app.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/sse/sse_event_consts.dart';
import 'package:vocechat_client/shared_funcs.dart';

typedef SseEventAware = void Function(dynamic);

class Sse {
  static final Sse sse = Sse._internal();

  html.EventSource? eventSource;

  Sse._internal();

  final Set<SseEventAware> sseEventListeners = {};

  int reconnectSec = 2;

  bool _afterReady = false;

  static const int _heartbeatInterval = 15;
  int _heartbeatCountDown = _heartbeatInterval;
  Timer? _heartbeatTimer;

  // SSE connection status variables
  // As SSE won't call its callbacks until an explicit status change happens,
  // a timer is needed to close the connection when it is stuck.
  bool isConnecting = false;
  static const int _maxConnectingTime = 10;
  int _connectingCountdown = _maxConnectingTime;
  Timer? _connectingTimer;

  Timer? _reconnectTimer;

  void connect() async {
    if (isConnecting) return;

    _setConnecting();

    close();
    App.logger.info("Connecting SSE: ${await prepareUrl()}");
    App.app.statusService.fireSseLoading(SseStatus.connecting);

    final eventSource =
        html.EventSource(Uri.parse(await prepareUrl()).toString());
    await SharedFuncs.updateServerInfo();

    try {
      eventSource.onMessage.listen((event) {
        App.app.statusService.fireSseLoading(SseStatus.successful);
        App.logger.info(event.data);

        if (event.data.toString().trim().isNotEmpty) {
          fireSseEvent(event.data);
          // _monitorSseLabel(event.data);
        }

        _resetConnecting();

        reconnectSec = 2;

        _resetHeartbeatCountdown();
      });

      eventSource.onOpen.listen((event) {
        App.app.statusService.fireSseLoading(SseStatus.successful);
        reconnectSec = 1;

        _resetConnecting();

        _cancelReconnectTimer();
        _setHeartbeatTimer();
      });

      eventSource.onError.listen((event) {
        App.app.statusService.fireSseLoading(SseStatus.disconnected);
        App.logger.severe(event);
        // _resetReadyFlag();
        eventSource.close();

        _resetConnecting();

        _handleReconnect();
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

  // Monitor if SSE stays in connecting status too long
  void _setConnecting() {
    _resetConnecting();

    isConnecting = true;

    _connectingTimer = Timer(Duration(seconds: _maxConnectingTime), () {
      isConnecting = false;
      close();
    });
  }

  void _resetConnecting() {
    isConnecting = false;
    _connectingTimer?.cancel();
  }

  /// Do SSE reconnection.
  ///
  /// Heartbeat timer will be cancelled. A periodic timer will be set to do
  /// reconnection with exponential retry interval (between 2 to 32 secs).
  void _handleReconnect() {
    _heartbeatTimer?.cancel();

    _reconnectTimer = Timer(Duration(seconds: reconnectSec), () {
      print("reconnect timer: $reconnectSec");
      connect();

      reconnectSec *= 2;
      if (reconnectSec >= 32) {
        reconnectSec = 32;
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    reconnectSec = 2;
  }

  void _resetHeartbeatCountdown() {
    _heartbeatCountDown = _heartbeatInterval;
  }

  void _setHeartbeatTimer() {
    print("set heartbeat timer");
    _heartbeatCountDown = _heartbeatInterval;
    _heartbeatTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      print("heartbeat countdown: $_heartbeatCountDown");
      if (_heartbeatCountDown <= 0) {
        _handleReconnect();
      }

      _heartbeatCountDown -= 5;
    });
  }

  // void _monitorSseLabel(dynamic event) {
  //   try {
  //     final map = json.decode(event) as Map<String, dynamic>;
  //     final type = map["type"];

  //     switch (type) {
  //       case sseHeartbeat:
  //         break;
  //       case sseReady:
  //         // _setReadyFlag();
  //         break;
  //       default:
  //     }
  //   } catch (e) {
  //     App.logger.warning(e);
  //   }
  // }

  Future<String> prepareUrl() async {
    String url = "${App.app.chatServerM.fullUrl}/api/user/events?";

    final afterMid = await UserDbMDao.dao.getMaxMid(App.app.userDb!.id);
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
    _resetConnecting();
    _reconnectTimer?.cancel();
    // _resetReadyFlag();
    App.logger.info("SSE Closed.");
  }
}
