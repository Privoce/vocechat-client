import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_retry/options.dart';
import 'package:vocechat_client/api/lib/dio_retry/retry_interceptor.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/shared_funcs.dart';

class DioUtil {
  final String baseUrl;

  static final _dio = Dio();

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
    if (enableRetry) {
      _dio.interceptors.add(RetryInterceptor(
          dio: _dio,
          options:
              RetryOptions(retries: 3, retryInterval: Duration(seconds: 2))));
    }
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = 5000; //5s
  }

  /// Handle http status 401  (token invalid)
  ///
  /// Will request new tokens (both access token and refresh token) using
  /// refresh token.
  void _addInvalidTokenInterceptor() async {
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onError: (e, handler) async {
        App.logger.severe(e);

        if (e.response != null &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          final isSuccessful = (await SharedFuncs.renewAuthToken());
          if (isSuccessful) {
            await _retry(e.response!.requestOptions)
                .then((res) => handler.resolve(res));
          } else {
            handler.resolve(e.response!);
          }
        } else {
          handler.resolve(Response(
              requestOptions: e.requestOptions,
              statusCode: e.response?.statusCode ?? 599));
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

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    _dio.interceptors.clear();

    return _dio.request<dynamic>(requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options);
  }
}
