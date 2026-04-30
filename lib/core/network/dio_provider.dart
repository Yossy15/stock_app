import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'retry_interceptor.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(DioRef ref) {
  final dio = Dio(
    BaseOptions(
      // baseUrl: 'http://localhost:3000/api', // Adjust for physical device
      baseUrl: 'https://stock-sdxt.vercel.app/api', // Vercel deployment
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // Add interceptors for logging, retry, etc.
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  dio.interceptors.add(RetryInterceptor(dio: dio));

  return dio;
}
