import 'package:dio/dio.dart';
import 'package:vocechat_client/app.dart';

import 'options.dart';

/// An interceptor that will try to send failed request again
class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryOptions options;

  RetryInterceptor({required this.dio, required this.options});

  @override
  Future<dynamic> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    var extra = RetryOptions.fromExtra(err.requestOptions, options);

    var shouldRetry = extra.retries > 0 &&
        (options.retryEvaluator != null
            ? await options.retryEvaluator!(err, handler)
            : await RetryOptions.defaultRetryEvaluator(err, handler));

    if (shouldRetry) {
      if (extra.retryInterval.inMilliseconds > 0) {
        await Future.delayed(extra.retryInterval);
      }

      // Update options to decrease retry count before new try
      extra = extra.copyWith(retries: extra.retries - 1);
      err.requestOptions.extra = err.requestOptions.extra
        ..addAll(extra.toExtra());
      err.requestOptions.headers["x-api-key"] = App.app.userDb!.token;

      final newOption = Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
          extra: err.requestOptions.extra,
          responseType: err.requestOptions.responseType,
          contentType: err.requestOptions.contentType,
          receiveTimeout: err.requestOptions.receiveTimeout,
          sendTimeout: err.requestOptions.sendTimeout,
          validateStatus: err.requestOptions.validateStatus,
          receiveDataWhenStatusError:
              err.requestOptions.receiveDataWhenStatusError,
          followRedirects: err.requestOptions.followRedirects,
          maxRedirects: err.requestOptions.maxRedirects,
          requestEncoder: err.requestOptions.requestEncoder,
          responseDecoder: err.requestOptions.responseDecoder,
          listFormat: err.requestOptions.listFormat);

      try {
        App.logger.warning(
            "[${err.requestOptions.uri}] An error occurred during request, trying again (remaining tries: ${extra.retries}, error: ${err.error})");

        return handler.resolve(await dio.request(err.requestOptions.path,
            cancelToken: err.requestOptions.cancelToken,
            data: err.requestOptions.data,
            onReceiveProgress: err.requestOptions.onReceiveProgress,
            onSendProgress: err.requestOptions.onSendProgress,
            queryParameters: err.requestOptions.queryParameters,
            options: newOption));
      } catch (e) {
        App.logger.severe(e);
        return handler.resolve(
            Response(requestOptions: err.requestOptions, statusCode: 599));
      }
    } else {
      App.logger.severe("won't retry; $err, path: ${err.requestOptions.path}");
      return handler.next(err);
    }
  }
}
