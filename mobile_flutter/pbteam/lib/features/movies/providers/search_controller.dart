import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tmdb_repository.dart';
import '../models/search_filters.dart';
import '../models/tmdb_movie.dart';

class SearchState {
  const SearchState({
    required this.query,
    required this.sort,
    required this.genre,
    required this.language,
    required this.year,
    required this.results,
    required this.page,
    required this.hasMore,
    required this.loading,
    required this.active,
    this.error,
  });

  final String query;
  final SearchSort sort;
  final SearchGenre genre;
  final SearchLanguage language;
  final SearchYearRange year;
  final List<TmdbMovie> results;
  final int page;
  final bool hasMore;
  final bool loading;
  final bool active;
  final String? error;

  SearchState copyWith({
    String? query,
    SearchSort? sort,
    SearchGenre? genre,
    SearchLanguage? language,
    SearchYearRange? year,
    List<TmdbMovie>? results,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? active,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      sort: sort ?? this.sort,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      year: year ?? this.year,
      results: results ?? this.results,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      active: active ?? this.active,
      error: error,
    );
  }

  static SearchState initial() => const SearchState(
        query: '',
        sort: SearchSort.popular,
        genre: SearchGenre.all,
        language: SearchLanguage.all,
        year: SearchYearRange.all,
        results: [],
        page: 1,
        hasMore: false,
        loading: false,
        active: false,
      );
}

class SearchController extends Notifier<SearchState> {
  late final TmdbRepository _repo;

  @override
  SearchState build() {
    _repo = ref.read(tmdbRepositoryProvider);
    return SearchState.initial();
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setSort(SearchSort value) {
    state = state.copyWith(sort: value);
  }

  void setGenre(SearchGenre value) {
    state = state.copyWith(genre: value);
  }

  void setLanguage(SearchLanguage value) {
    state = state.copyWith(language: value);
  }

  void setYear(SearchYearRange value) {
    state = state.copyWith(year: value);
  }

  Future<void> search({SearchSort? overrideSort}) async {
    if (state.loading) return;
    final sort = overrideSort ?? state.sort;
    state = state.copyWith(
      loading: true,
      page: 1,
      hasMore: true,
      active: true,
      sort: sort,
      error: null,
    );
    try {
      final results = await _fetchPage(sort: sort, page: 1);
      state = state.copyWith(
        results: results,
        hasMore: results.isNotEmpty,
        page: 1,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore || !state.active) return;
    final nextPage = state.page + 1;
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await _fetchPage(sort: state.sort, page: nextPage);
      state = state.copyWith(
        results: [...state.results, ...results],
        page: nextPage,
        hasMore: results.isNotEmpty,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void reset() {
    state = SearchState.initial();
  }

  Future<List<TmdbMovie>> _fetchPage({required SearchSort sort, required int page}) {
    final trimmed = state.query.trim();
    if (trimmed.isNotEmpty) {
      return _repo.searchMovies(trimmed, page: page);
    }
    return _repo.discover(
      sort: sort,
      genre: state.genre,
      language: state.language,
      year: state.year,
      page: page,
    );
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
