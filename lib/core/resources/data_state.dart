import 'package:dio/dio.dart';

abstract class DataState<T> {
  final T? data;
  final DioException? exception;
  final AppError? error;

  const DataState({this.data, this.exception, this.error});
}

class DataSuccess<T> extends DataState<T> {
  const DataSuccess(T data) : super(data: data);
}

class DataFailed<T> extends DataState<T> {
  const DataFailed(DioException exception) : super(exception: exception);
}

// TODO: to be extended to include other types of errors
class InternalError<T> extends DataState<T> {
  const InternalError(AppError error) : super(error: error);
}

// TODO: to be extended to include other types of errors
class AppError extends Error {
  final String message;

  AppError(this.message);

  @override
  String toString() {
    return message;
  }
}
