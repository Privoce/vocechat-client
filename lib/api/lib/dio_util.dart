import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DioUtil {
  final String baseUrl;

  final _dio = Dio();

  DioUtil({required this.baseUrl, bool enableRetry = true}) {
    _init(enableRetry: enableRetry);
  }

  DioUtil.token(
      {required this.baseUrl,
      bool enableRetry = true,
      bool enableTokenHandler = true}) {
    _init(enableRetry: enableRetry);
    _dio.options.headers["x-api-key"] = App.app.userDb!.token;

    if (enableTokenHandler) {
      _addInvalidTokenInterceptor();
    }
  }

  void _init({bool enableRetry = true}) {
    // _dio.httpClientAdapter = Http2Adapter(ConnectionManager());
    _dio.options.headers = {'referer': App.app.chatServerM.fullUrl};

    if (enableRetry) {
      _dio.interceptors.add(RetryInterceptor(
          dio: _dio,
          options:
              RetryOptions(retries: 3, retryInterval: Duration(seconds: 2))));
    }
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = 5000; //5s
    // _dio.options.receiveTimeout = 10000;
  }

  /// Handle http status 401  (token invalid)
  ///
  /// Will request new tokens (both access token and refresh token) using
  /// refresh token.
  void _addInvalidTokenInterceptor() async {
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) async {
        if (response.statusCode == 401 || response.statusCode == 403) {
          final res = (await App.app.authService?.renewAuthToken()) ?? false;
          print(res);
        }
      },
      onError: (e, handler) async {
        if (e.response != null && e.response!.statusCode == 401) {
          final res = (await App.app.authService?.renewAuthToken()) ?? false;
          print(res);
          if (!res) {
            // alert and jump to login if failed.
            // if (navigatorKey.currentContext != null) {
            //   final context = navigatorKey.currentContext!;
            //   showAppAlert(
            //       context: context,
            //       title: "Authentication Error",
            //       content: "Please login again.",
            //       primaryAction: AppAlertDialogAction(
            //           text: "Continue",
            //           action: () {
            //             Navigator.of(navigatorKey.currentContext!).pop();
            //             App.app.authService?.logout();
            //           }),
            //       actions: [
            //         AppAlertDialogAction(
            //             text: AppLocalizations.of(navigatorKey.currentContext!)!
            //                 .cancel,
            //             action: () =>
            //                 Navigator.of(navigatorKey.currentContext!).pop())
            //       ]);
            // }
          }
        }
      },
    ));
  }

  /// Handy method to make http POST request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.post(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }

  /// Handy method to make http GET request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.get(path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }

  ///Handy method to make http DELETE request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.put(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }

  BaseOptions get options {
    return _dio.options;
  }
}
