import 'dart:async';

import 'package:dio/dio.dart';

typedef RetryEvaluator = FutureOr<bool> Function(
    DioError error, ErrorInterceptorHandler handler);

class RetryOptions {
  /// The number of retry in case of an error
  final int retries;

  /// The interval before a retry.
  final Duration retryInterval;

  final RetryEvaluator? retryEvaluator;

  const RetryOptions(
      {this.retries = 3,
      this.retryEvaluator,
      this.retryInterval = const Duration(seconds: 3)});

  factory RetryOptions.noRetry() {
    return RetryOptions(
      retries: 0,
    );
  }

  static const extraKey = "cache_retry_request";

  /// Returns [true] only if the response hasn't been cancelled or got
  /// a bas status code.
  static FutureOr<bool> defaultRetryEvaluator(
      DioError error, ErrorInterceptorHandler handler) {
    return error.type != DioErrorType.cancel &&
        error.type != DioErrorType.badResponse;
  }

  factory RetryOptions.fromExtra(RequestOptions request, RetryOptions options) {
    return request.extra[extraKey] ?? options;
  }

  RetryOptions copyWith({int? retries, Duration? retryInterval}) {
    return RetryOptions(
        retries: retries ?? this.retries,
        retryInterval: retryInterval ?? this.retryInterval);
  }

  Map<String, dynamic> toExtra() {
    return {
      extraKey: this,
    };
  }

  Options toOptions() {
    return Options(extra: toExtra());
  }

  Options mergeIn(Options options) {
    return options.copyWith(
        extra: <String, dynamic>{}
          ..addAll(options.extra ?? {})
          ..addAll(toExtra()));
  }
}
