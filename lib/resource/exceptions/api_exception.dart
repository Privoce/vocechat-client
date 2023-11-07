import 'package:dio/dio.dart';

class ApiException {
  final DioException? dioException;
  final String? additionalMsg;

  ApiException({this.dioException, this.additionalMsg});
}
