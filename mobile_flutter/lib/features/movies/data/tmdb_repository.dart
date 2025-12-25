import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/search_filters.dart';
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

  Future<TmdbMovie> fetchDetails(int id) async {
    final res = await _dio.get('/movie/$id', queryParameters: {
      'language': 'ko-KR',
    });
    return TmdbMovie.fromJson(res.data as Map<String, dynamic>);
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

  Future<List<TmdbMovie>> discover({
    required SearchSort sort,
    required SearchGenre genre,
    required SearchLanguage language,
    required SearchYearRange year,
    int page = 1,
  }) async {
    final genreIdMap = <SearchGenre, int>{
      SearchGenre.action: 28,
      SearchGenre.adventure: 12,
      SearchGenre.animation: 16,
      SearchGenre.comedy: 35,
      SearchGenre.crime: 80,
      SearchGenre.drama: 18,
      SearchGenre.fantasy: 14,
      SearchGenre.horror: 27,
      SearchGenre.romance: 10749,
      SearchGenre.scifi: 878,
      SearchGenre.thriller: 53,
    };
    final sortMap = <SearchSort, String>{
      SearchSort.popular: 'popularity.desc',
      SearchSort.latest: 'primary_release_date.desc',
      SearchSort.rating: 'vote_average.desc',
      SearchSort.title: 'original_title.asc',
    };

    String? gte;
    String? lte;
    switch (year) {
      case SearchYearRange.y2020plus:
        gte = '2020-01-01';
        break;
      case SearchYearRange.y2010s:
        gte = '2010-01-01';
        lte = '2019-12-31';
        break;
      case SearchYearRange.y2000s:
        gte = '2000-01-01';
        lte = '2009-12-31';
        break;
      case SearchYearRange.y1990s:
        gte = '1990-01-01';
        lte = '1999-12-31';
        break;
      case SearchYearRange.pre1990:
        lte = '1989-12-31';
        break;
      case SearchYearRange.all:
        break;
    }

    final res = await _dio.get('/discover/movie', queryParameters: {
      'page': page,
      'sort_by': sortMap[sort],
      if (genre != SearchGenre.all) 'with_genres': genreIdMap[genre],
      if (language != SearchLanguage.all) 'with_original_language': language.name,
      if (gte != null) 'primary_release_date.gte': gte,
      if (lte != null) 'primary_release_date.lte': lte,
      'language': 'ko-KR',
    });
    return _mapResults(res);
  }
}

final tmdbRepositoryProvider = Provider<TmdbRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TmdbRepository(dio);
});
