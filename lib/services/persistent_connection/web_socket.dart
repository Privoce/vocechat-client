import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/persistent_connection/persistent_connection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VoceWebSocket extends PersistentConnection {
  static final VoceWebSocket _singleton = VoceWebSocket._internal();

  VoceWebSocket._internal() {
    type = PersistentConnectionType.websocket;
  }

  factory VoceWebSocket() {
    return _singleton;
  }

  WebSocketChannel? channel;

  @override
  Future<bool> checkAvailability() async {
    final url = await prepareConnectionUrl(type);

    try {
      await channel?.sink.close();
      final testChannel = WebSocketChannel.connect(Uri.parse(url));
      await testChannel.stream.first;
      await testChannel.sink.close();

      return true;
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
  }

  @override
  Future<void> connect() async {
    if (isConnecting) return;

    isConnecting = true;
    fireAfterReady(false);
    await close();

    final url = await prepareConnectionUrl(type);
    App.logger.info("Connecting WebSocket: $url");
    App.app.statusService?.fireSseLoading(PersConnStatus.connecting);

    try {
      channel = WebSocketChannel.connect(Uri.parse(url));

      channel?.stream.listen((event) {
        App.app.statusService?.fireSseLoading(PersConnStatus.successful);
        App.logger.info(event);

        isConnected = true;
        isConnecting = false;
        resetReconnectionDelay();

        fireServerEvent(event);
      }, onError: (error) {
        onError(error);
      });
    } catch (error) {
      onError(error);
    }

    return;
  }

  @override
  Future<void> close() async {
    if (channel != null) {
      await channel?.sink.close();
      channel = null;
    }

    await generalClose();
  }
}
