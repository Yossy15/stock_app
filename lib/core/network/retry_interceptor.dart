import 'dart:io';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    var retries = err.requestOptions.extra['retries'] ?? 0;

    if (_shouldRetry(err) && retries < maxRetries) {
      retries++;
      err.requestOptions.extra['retries'] = retries;

      // Exponential backoff
      final delay = retryInterval * retries;
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.type == DioExceptionType.unknown && err.error is SocketException);
  }
}
