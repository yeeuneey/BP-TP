import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tmdb_repository.dart';
import '../models/tmdb_movie.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<TmdbMovie>>((ref) async {
  final repo = ref.watch(tmdbRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.searchMovies(query);
});
