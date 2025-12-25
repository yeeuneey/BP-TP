import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../movies/data/tmdb_repository.dart';
import '../movies/models/tmdb_movie.dart';

class PopularState {
  const PopularState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.loading,
    this.error,
  });

  final List<TmdbMovie> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final String? error;

  bool get initialLoading => loading && items.isEmpty;

  PopularState copyWith({
    List<TmdbMovie>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    String? error,
  }) {
    return PopularState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  factory PopularState.initial() {
    return const PopularState(
      items: [],
      page: 0,
      hasMore: true,
      loading: true,
      error: null,
    );
  }
}

class PopularController extends Notifier<PopularState> {
  late final TmdbRepository _repo;
  bool _initialized = false;

  @override
  PopularState build() {
    _repo = ref.read(tmdbRepositoryProvider);
    if (!_initialized) {
      _initialized = true;
      Future.microtask(loadInitial);
    }
    return PopularState.initial();
  }

  Future<void> loadInitial() async {
    await _load(page: 1, replace: true);
  }

  Future<void> refresh() async {
    await _load(page: 1, replace: true);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final nextPage = state.page + 1;
    await _load(page: nextPage, replace: false);
  }

  Future<void> _load({required int page, required bool replace}) async {
    if (state.loading && !replace) return;
    state = state.copyWith(
      loading: true,
      error: null,
      page: replace ? 0 : state.page,
      hasMore: replace ? true : state.hasMore,
    );
    try {
      final results = await _repo.fetchPopular(page: page);
      final hydrated = await _hydrate(results);
      final merged = replace ? hydrated : [...state.items, ...hydrated];
      state = state.copyWith(
        items: merged,
        page: page,
        hasMore: hydrated.isNotEmpty,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        hasMore: replace ? false : state.hasMore,
      );
    }
  }

  Future<List<TmdbMovie>> _hydrate(List<TmdbMovie> items) async {
    return Future.wait(
      items.map((m) async {
        try {
          final detail = await _repo.fetchDetails(m.id);
          return m.merge(detail);
        } catch (_) {
          return m;
        }
      }),
    );
  }
}

final popularControllerProvider =
    NotifierProvider<PopularController, PopularState>(PopularController.new);
