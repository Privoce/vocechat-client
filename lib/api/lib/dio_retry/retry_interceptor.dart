import 'package:dio/dio.dart';
import 'package:vocechat_client/app.dart';

import 'options.dart';

/// An interceptor that will try to send failed request again
class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryOptions options;

  RetryInterceptor({required this.dio, required this.options});

  @override
  Future<dynamic> onError(DioError err, ErrorInterceptorHandler handler) async {
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

      try {
        App.logger.warning(
            "[${err.requestOptions.uri}] An error occured during request, trying a again (remaining tries: ${extra.retries}, error: ${err.error})");

        return handler.resolve(await dio.request(err.requestOptions.path,
            cancelToken: err.requestOptions.cancelToken,
            data: err.requestOptions.data,
            onReceiveProgress: err.requestOptions.onReceiveProgress,
            onSendProgress: err.requestOptions.onSendProgress,
            queryParameters: err.requestOptions.queryParameters,
            options: extra.toOptions()));
      } catch (e) {
        App.logger.severe(e);
        return handler.resolve(
            Response(requestOptions: err.requestOptions, statusCode: 599));
      }
    } else {
      App.logger.severe(err);
      return handler.resolve(
          Response(requestOptions: err.requestOptions, statusCode: 599));
    }

    // return super.onError(err, handler);
  }
}
