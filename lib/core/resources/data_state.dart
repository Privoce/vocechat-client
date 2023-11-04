import 'package:dio/dio.dart';

abstract class DataState<T> {
  final T? data;
  final DioException? exception;
  final Error? error;

  const DataState({this.data, this.exception, this.error});
}

class DataSuccess<T> extends DataState<T> {
  const DataSuccess(T data) : super(data: data);
}

class DataFailed<T, E> extends DataState<T> {
  const DataFailed.network(DioException exception)
      : super(exception: exception);

  const DataFailed.error(Error error) : super(error: error);
}
