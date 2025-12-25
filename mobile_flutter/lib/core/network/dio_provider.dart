import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  if (AppConfig.tmdbApiKey.isEmpty) {
    throw StateError('TMDB_API_KEY is missing (--dart-define).');
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.queryParameters.putIfAbsent('api_key', () => AppConfig.tmdbApiKey);
        return handler.next(options);
      },
    ),
  );

  return dio;
});
