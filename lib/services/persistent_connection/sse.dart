import 'package:dio/dio.dart';
import 'package:universal_html/html.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/persistent_connection/persistent_connection.dart';

class VoceSse extends PersistentConnection {
  static final VoceSse _singleton = VoceSse._internal();

  VoceSse._internal() {
    type = PersistentConnectionType.sse;
  }

  factory VoceSse() {
    return _singleton;
  }

  EventSource? eventSource;

  @override
  Future<bool> checkAvailability() async {
    final url = await prepareConnectionUrl(type);

    try {
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }

    return false;
  }

  @override
  Future<void> connect() async {
    if (isConnecting) return;

    isConnecting = true;
    fireAfterReady(false);

    close();

    final url = await prepareConnectionUrl(type);
    App.logger.info("Connecting SSE: $url");
    App.app.statusService?.fireSseLoading(PersConnStatus.connecting);

    final eventSource = EventSource(Uri.parse(url).toString());

    try {
      eventSource.onMessage.listen((event) {
        App.app.statusService?.fireSseLoading(PersConnStatus.successful);
        App.logger.info(event.data);

        isConnecting = false;
        isConnected = true;
        resetReconnectionDelay();

        if (event.data.toString().trim().isNotEmpty) {
          fireServerEvent(event.data);
        }
      });

      eventSource.onOpen.listen((event) {
        App.app.statusService?.fireSseLoading(PersConnStatus.successful);
        isConnecting = false;
        isConnected = true;
        resetReconnectionDelay();
      });

      eventSource.onError.listen((event) {
        onError(event);
      });
    } catch (e) {
      App.logger.severe(e);

      onError(e);
    }

    this.eventSource = eventSource;
  }

  @override
  Future<void> close() async {
    eventSource?.close();
    eventSource = null;

    await generalClose();
  }
}
