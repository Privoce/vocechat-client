// import 'dart:async';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/sse/server_event_consts.dart';
import 'package:vocechat_client/shared_funcs.dart';

/// Used for distinguishing connection types in [PersistentConnection] abstract
/// class.
enum PersistentConnectionType { sse, websocket }

/// Base class for persistent connections.
///
/// Should be implemented into a Singleton class.
/// use *extends* keyword in subclasses as some methods have already been
/// implemented.
abstract class PersistentConnection {
  PersistentConnectionType _type = PersistentConnectionType.sse;
  PersistentConnectionType get type => _type;
  set type(PersistentConnectionType value) => _type = value;

  /// This variable is used to prevent multiple connection attempts.
  bool _isConnecting = false;

  @protected
  bool get isConnecting => _isConnecting;

  @protected
  set isConnecting(bool value) => _isConnecting = value;

  /// This variable is used for checking if the connection is established.
  ///
  /// If connection fails, this flag will be set to false.
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  set isConnected(bool value) => _isConnected = value;

  /// Reconnection time interval in secend.
  ///
  /// Reconnect interval starts from 1 second, and grows exponentially up to
  /// 32 seconds.
  int reconnectSec = 1;

  /// This variable is used for reconnecting to the server.
  Timer? _reconnectTimer;

  @protected
  Timer? get reconnectTimer => _reconnectTimer;

  @protected
  set reconnectTimer(Timer? value) => _reconnectTimer = value;

  final Set<ServerEventAware> _serverEventListeners = {};
  final Set<ServerEventReadyAware> _readyListeners = {};

  /// Connect to server for events.
  Future<void> connect();

  /// Handle reconnection in case of connection failure.
  ///
  /// Should include reconnect time interval awaiting strategy.
  Future<void> reconnect() async {
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

  void resetReconnectionDelay() {
    reconnectSec = 1;
    _reconnectTimer?.cancel();
  }

  /// Handle connection error.
  ///
  /// Should include following logics:
  /// 1. Close the connection.
  /// 2. Call [reconnect] method.
  /// 3. Log the error.
  ///
  /// Fire [PersConnStatus.disconnected] event;
  /// [_isConnected], [_isConnecting] set to false
  /// are inclided in [close] method.
  void onError(dynamic error) {
    App.logger.severe("Error connecting to ${type.name}: $error");
    close();
    reconnect();
  }

  /// Close the connection.
  ///
  /// Should only include the stream close and [generalClose] method in override.
  /// All other status flags and [PersConnStatus.disconnected] event firing is
  /// handled in [generalClose] member method.
  Future<void> close();

  /// Handle connection close.
  ///
  /// Must include following logics:
  /// 1. Set [_isConnected] to false.
  /// 2. Set [_isConnecting] to false.
  /// 2. Fire [PersConnStatus.disconnected] event.
  /// 3. Fire [afterReady] event with false value.
  /// 4. Cancel reconnection timer.
  Future<void> generalClose() async {
    _isConnected = false;
    _isConnecting = false;
    App.app.statusService?.fireSseLoading(PersConnStatus.disconnected);
    fireAfterReady(false);
    App.logger.info("Persistent Connection (${type.name}) closed.");
  }

  Future<bool> checkAvailability();

  Future<String> prepareConnectionUrl(PersistentConnectionType type) async {
    try {
      final uri = Uri.parse(App.app.chatServerM.fullUrl);
      String url;

      switch (type) {
        case PersistentConnectionType.sse:
          url = "${uri.scheme}://${uri.host}:${uri.port}/api/user/events?";
          break;
        case PersistentConnectionType.websocket:
          String scheme = uri.scheme == "https" ? "wss" : "ws";
          url = "$scheme://${uri.host}:${uri.port}/api/user/events_ws?";
          break;
        default:
          throw Exception("Unknown connection type: $type");
      }

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
    } catch (e) {
      App.logger.severe(e);
      return "";
    }
  }

  void subscribeServerEvent(ServerEventAware aware) {
    unsubscribeAllSseEvents();
    _serverEventListeners.add(aware);
  }

  void unsubscribeServerEvent(ServerEventAware aware) {
    _serverEventListeners.remove(aware);
  }

  void unsubscribeAllSseEvents() {
    _serverEventListeners.clear();
  }

  void subscribeReady(ServerEventReadyAware aware) {
    unsubscribeReady(aware);
    _readyListeners.add(aware);
  }

  void unsubscribeReady(ServerEventReadyAware aware) {
    _readyListeners.remove(aware);
  }

  void unsubscribeAllReadyListeners() {
    _readyListeners.clear();
  }

  void fireServerEvent(dynamic event) {
    for (ServerEventAware sseEventAware in _serverEventListeners) {
      try {
        sseEventAware(event);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireAfterReady(bool afterReady) {
    for (ServerEventReadyAware aware in _readyListeners) {
      try {
        aware(afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }
}
