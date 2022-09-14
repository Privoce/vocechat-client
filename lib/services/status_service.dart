import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';

class StatusService {
  final Set<LoadingAware> _tokenListeners = {};
  final Set<LoadingAware> _sseListeners = {};
  final Set<LoadingAware> _taskListeners = {};

  void subscribeTokenLoading(LoadingAware loadingAware) {
    unsubscribeTokenLoading(loadingAware);
    _tokenListeners.add(loadingAware);
  }

  void unsubscribeTokenLoading(LoadingAware loadingAware) {
    _tokenListeners.remove(loadingAware);
  }

  void fireTokenLoading(LoadingStatus status) {
    for (LoadingAware loadingAware in _tokenListeners) {
      try {
        loadingAware(status);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void subscribeSseLoading(LoadingAware loadingAware) {
    unsubscribeSseLoading(loadingAware);
    _sseListeners.add(loadingAware);
  }

  void unsubscribeSseLoading(LoadingAware loadingAware) {
    _sseListeners.remove(loadingAware);
  }

  void fireSseLoading(LoadingStatus status) {
    for (LoadingAware loadingAware in _sseListeners) {
      try {
        loadingAware(status);
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
