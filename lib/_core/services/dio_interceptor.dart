import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_listin/_core/services/dio_endpoints.dart';
import 'package:logger/logger.dart';

class DioInterceptor extends Interceptor {
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    String logRequest = '';

    logRequest += 'Request\n';
    logRequest += 'Timestamp: ${DateTime.now()}\n';
    logRequest += 'uri: ${options.uri}\n';
    logRequest += 'method: ${options.method}\n';
    logRequest += 'headers: ${const JsonEncoder.withIndent("  ").convert(
      options.headers,
    )}\n';

    if (options.data != null) {
      logRequest +=
          'data: ${const JsonEncoder.withIndent("  ").convert(json.decode(
        options.data,
      ))}\n';
    }

    _logger.i(logRequest);
    Dio().post('${DioEndpoints.baseUrl}${DioEndpoints.logs}',
        data: {'request': logRequest});

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    String logReponse = '';
    logReponse += 'Response\n';
    logReponse += 'Timestamp: ${DateTime.now()}\n';
    logReponse += 'statusCode: ${response.statusCode}\n';
    logReponse += '${response.statusMessage} \n';

    _logger.i(logReponse);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String logError = '';

    logError += 'Error\n';
    logError += 'Timestamp: ${DateTime.now()}\n';
    logError += '${err.message}';

    _logger.f(logError);
    super.onError(err, handler);
  }
}
