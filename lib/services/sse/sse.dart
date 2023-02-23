import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vocechat_client/app.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/shared_funcs.dart';

typedef SseEventAware = void Function(dynamic);

class Sse {
  static final Sse sse = Sse._internal();

  factory Sse() {
    return sse;
  }

  Sse._internal();

  html.EventSource? eventSource;

  final Set<SseEventAware> sseEventListeners = {};

  bool _isConnecting = false;

  /// For the situation where the SSE keeps connecting
  /// but connection is not established.
  Timer? _connectingTimer;

  /// Do reconnection when any SSE message has not been received for longer than
  /// a time period.
  Timer? _heartbeatTimer;

  void connect() async {
    if (_isConnecting) return;

    if (!(await _networkIsAvailable())) {
      App.app.statusService?.fireSseLoading(SseStatus.disconnected);
      return;
    }

    // Order must be maintained as follow: close -> _isConnecting = true
    close();

    _isConnecting = true;

    App.logger.info("Connecting SSE: ${await prepareUrl()}");
    App.app.statusService?.fireSseLoading(SseStatus.connecting);

    // _startConnectingTimer();

    final eventSource =
        html.EventSource(Uri.parse(await prepareUrl()).toString());
    SharedFuncs.updateServerInfo();

    try {
      eventSource.onMessage.listen((event) {
        App.app.statusService?.fireSseLoading(SseStatus.successful);
        App.logger.info(event.data);

        if (event.data.toString().trim().isNotEmpty) {
          fireSseEvent(event.data);
        }

        // _cancelConnectingTimer();
        // _startHeartbeatTimer();
      });

      eventSource.onOpen.listen((event) {
        App.app.statusService?.fireSseLoading(SseStatus.successful);

        // _cancelConnectingTimer();
        // _startHeartbeatTimer();
      });

      eventSource.onError.listen((event) {
        App.app.statusService?.fireSseLoading(SseStatus.disconnected);
        App.logger.severe(event);

        // _cancelConnectingTimer();
        // _cancelHeartbeatTimer();
        eventSource.close();
      });
    } catch (e) {
      App.logger.severe(e);
    }

    this.eventSource = eventSource;
  }

  Future<bool> _networkIsAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    return (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi);
  }

  void subscribeSseEvent(SseEventAware aware) {
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
    _isConnecting = false;

    App.app.statusService?.fireSseLoading(SseStatus.disconnected);

    _cancelConnectingTimer();

    App.logger.info("SSE Closed.");
  }

  // Following functions are for the situation where the SSE keeps connecting
  // but connection is not established.

  /// Starts a timer that counts how long SSE keeps in trying-to-connect status.
  ///
  /// [_connectingTimer] will be cancelled when SSE connection establishes, or
  /// an error occurred, or it keeps trying to connect for more than
  /// [maxConnectingWaitingSecs].
  void _startConnectingTimer() {
    const maxConnectingWaitingSecs = 10;
    _cancelConnectingTimer();

    _connectingTimer = Timer(Duration(seconds: maxConnectingWaitingSecs), () {
      close();
    });
  }

  void _cancelConnectingTimer() {
    _connectingTimer?.cancel();
  }

  /// Starts a timer that reconnect SSE when the app has not received an SSE
  /// event for more than [maxHeartbeatInterval] seconds.
  void _startHeartbeatTimer() {
    const int maxHeartbeatInterval = 15;
    _cancelHeartbeatTimer();

    _heartbeatTimer =
        Timer.periodic(Duration(seconds: maxHeartbeatInterval), (timer) {
      connect();
    });
  }

  void _cancelHeartbeatTimer() {
    _heartbeatTimer?.cancel();
  }
}
