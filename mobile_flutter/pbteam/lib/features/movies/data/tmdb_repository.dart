import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/tmdb_movie.dart';

class TmdbRepository {
  TmdbRepository(this._dio);

  final Dio _dio;

  Future<List<TmdbMovie>> fetchPopular({int page = 1}) => _fetchList('/movie/popular', page);

  Future<List<TmdbMovie>> fetchNowPlaying({int page = 1}) =>
      _fetchList('/movie/now_playing', page);

  Future<List<TmdbMovie>> fetchTopRated({int page = 1}) => _fetchList('/movie/top_rated', page);

  Future<List<TmdbMovie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    final res = await _dio.get('/search/movie', queryParameters: {
      'query': query,
      'page': page,
      'include_adult': false,
      'language': 'ko-KR',
    });
    return _mapResults(res);
  }

  Future<List<TmdbMovie>> _fetchList(String path, int page) async {
    final res = await _dio.get(path, queryParameters: {
      'page': page,
      'language': 'ko-KR',
    });
    return _mapResults(res);
  }

  List<TmdbMovie> _mapResults(Response res) {
    final results = (res.data['results'] as List<dynamic>? ?? []);
    return results.map((e) => TmdbMovie.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final tmdbRepositoryProvider = Provider<TmdbRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TmdbRepository(dio);
});
