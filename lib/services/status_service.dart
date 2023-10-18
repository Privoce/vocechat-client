import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class StatusService {
  final Set<TokenAware> _tokenListeners = {};
  final Set<SseAware> _sseListeners = {};
  final Set<LoadingAware> _taskListeners = {};

  void dispose() {
    _tokenListeners.clear();
    _sseListeners.clear();
    _taskListeners.clear();
  }

  void subscribeTokenLoading(TokenAware tokenAware) {
    unsubscribeTokenLoading(tokenAware);
    _tokenListeners.add(tokenAware);
  }

  void unsubscribeTokenLoading(TokenAware tokenAware) {
    _tokenListeners.remove(tokenAware);
  }

  void fireTokenLoading(TokenStatus status) {
    for (TokenAware tokenAware in _tokenListeners) {
      try {
        tokenAware(status);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void subscribeSseLoading(SseAware sseAware) {
    unsubscribeSseLoading(sseAware);
    _sseListeners.add(sseAware);
  }

  void unsubscribeSseLoading(SseAware sseAware) {
    _sseListeners.remove(sseAware);
  }

  void fireSseLoading(PersConnStatus status) {
    for (SseAware sseAware in _sseListeners) {
      try {
        sseAware(status);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void subscribeTaskLoading(LoadingAware loadingAware) {
    unsubscribeTaskLoading(loadingAware);
    _taskListeners.add(loadingAware);
  }

  void unsubscribeTaskLoading(LoadingAware loadingAware) {
    _taskListeners.remove(loadingAware);
  }

  void fireTaskLoading(LoadingStatus status) {
    for (LoadingAware loadingAware in _taskListeners) {
      try {
        loadingAware(status);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }
}
