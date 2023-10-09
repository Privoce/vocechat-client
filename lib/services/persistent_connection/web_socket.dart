import 'dart:async';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/sse/sse.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VoceWebSocket {
  static final VoceWebSocket _singleton = VoceWebSocket._internal();
  VoceWebSocket._internal();

  final Set<ServerEventAware> serverEventListeners = {};
  final Set<ServerEventReadyAware> readyListeners = {};

  factory VoceWebSocket() {
    return _singleton;
  }

  bool isConnecting = false;

  WebSocketChannel? channel;

  // Reconnect interval starts from 1 second, and grows exponentially up to
  // 32 seconds.
  int reconnectSec = 1;
  Timer? _reconnectTimer;

  void connect() async {
    if (isConnecting) return;

    isConnecting = true;
    fireAfterReady(false);
    close();

    final url = await prepareUrl();
    App.logger.info("Connecting WebSocket: $url");
    App.app.statusService?.fireSseLoading(SseStatus.connecting);

    try {
      channel = WebSocketChannel.connect(Uri.parse(url));

      channel?.stream.listen((event) {
        App.app.statusService?.fireSseLoading(SseStatus.successful);
        reconnectSec = 1;
        cancelReconnectionDelay();
        isConnecting = false;

        fireServerEvent(event);
      }, onError: (error) {
        onError(error);
        App.app.statusService?.fireSseLoading(SseStatus.disconnected);
      });
    } catch (error) {
      onError(error);
    }
  }

  void onError(dynamic e) {
    App.logger.info("Error connecting to websocket: $e");
    isConnecting = false;
    close();
    tryReconnection();
  }

  void tryReconnection() async {
    _reconnectTimer = Timer(Duration(seconds: reconnectSec), () async {
      if (await SharedFuncs.renewAuthToken(forceRefresh: true)) {
        connect();
      }

      reconnectSec *= 2;
      if (reconnectSec >= 32) {
        reconnectSec = 32;
      }
    });
  }

  void cancelReconnectionDelay() {
    _reconnectTimer?.cancel();
  }

  void close() {
    channel?.sink.close();
  }

  Future<String> prepareUrl() async {
    final uri = Uri.parse(App.app.chatServerM.fullUrl);
    String scheme = uri.scheme == "https" ? "wss" : "ws";

    String url = "$scheme://${uri.host}:${uri.port}/api/user/events_ws?";

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

  void subscribeServerEvent(ServerEventAware aware) {
    unsubscribeAllSseEvents();
    serverEventListeners.add(aware);
  }

  void unsubscribeServerEvent(ServerEventAware aware) {
    serverEventListeners.remove(aware);
  }

  void unsubscribeAllSseEvents() {
    serverEventListeners.clear();
  }

  void subscribeReady(ServerEventReadyAware aware) {
    unsubscribeReady(aware);
    readyListeners.add(aware);
  }

  void unsubscribeReady(ServerEventReadyAware aware) {
    readyListeners.remove(aware);
  }

  void unsubscribeAllReadyListeners() {
    readyListeners.clear();
  }

  void fireServerEvent(dynamic event) {
    for (ServerEventAware sseEventAware in serverEventListeners) {
      try {
        sseEventAware(event);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireAfterReady(bool afterReady) {
    for (ServerEventReadyAware aware in readyListeners) {
      try {
        aware(afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }
}
