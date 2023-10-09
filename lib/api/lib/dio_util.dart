import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';

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
    // Clear current options for new requests.
    _dio.options = BaseOptions();
    _dio.interceptors.clear();

    if (enableRetry) {
      _dio.interceptors.add(RetryInterceptor(
          dio: _dio,
          options:
              RetryOptions(retries: 3, retryInterval: Duration(seconds: 2))));
    } else {
      _dio.interceptors.add(RetryInterceptor(
          dio: _dio,
          options:
              RetryOptions(retries: 0, retryInterval: Duration(seconds: 1))));
    }
    _dio.options.baseUrl = baseUrl;

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // print("************** createHttpClient");
        // Don't trust any certificate just because their root cert is trusted.
        final HttpClient client =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        // You can test the intermediate / root cert here. We just ignore it.
        client.badCertificateCallback = (cert, host, port) {
          // print("************** badCertificateCallback");
          return true;
        };

        return client;
      },
      validateCertificate: (certificate, host, port) {
        // print("************** validateCertificate");
        return true;
      },
    );

    // _dio.options.connectTimeout = 5000; //5s
  }

  /// Handle http status 401  (token invalid)
  ///
  /// Will request new tokens (both access token and refresh token) using
  /// refresh token.
  void _addInvalidTokenInterceptor() async {
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onError: (e, handler) async {
        App.logger.warning(e);
        if (e.response != null &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          _handle401(e.response!, handler);
        } else if (e.response != null && e.response?.statusCode == 413) {
          _handle413(e.response!, handler);
        } else {
          handler.resolve(Response(
              requestOptions: e.requestOptions,
              statusCode: e.response?.statusCode ?? 599));
        }
      },
    ));
  }

  void _handle401(
      Response<dynamic> response, ErrorInterceptorHandler handler) async {
    final isSuccessful = (await SharedFuncs.renewAuthToken());
    if (isSuccessful) {
      await _retry(response.requestOptions, response.requestOptions.baseUrl)
          .then((res) {
        handler.resolve(res);
      }).onError((error, stackTrace) {
        handler.reject(DioException(
            requestOptions: response.requestOptions, error: error));
      });
    } else {
      App.logger.severe("Token refresh failed");
      App.app.statusService?.fireTokenLoading(TokenStatus.unauthorized);
      handler.resolve(response);
    }
  }

  void _handle413(
      Response<dynamic> response, ErrorInterceptorHandler handler) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.fileUploadError,
          content: AppLocalizations.of(context)!.fileSizeTooLargeDes,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.of(context).pop())
          ]);
    }
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

  Future<Response<dynamic>> _retry(
      RequestOptions requestOptions, String baseUrl) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    options.headers?["x-api-key"] = App.app.userDb!.token;

    _dio.interceptors.clear();
    _dio.options.baseUrl = baseUrl;

    return _dio.request<dynamic>(requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options);
  }
}
