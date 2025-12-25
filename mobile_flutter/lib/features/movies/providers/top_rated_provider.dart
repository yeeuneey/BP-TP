import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tmdb_repository.dart';
import '../models/tmdb_movie.dart';

final topRatedProvider = FutureProvider<List<TmdbMovie>>((ref) async {
  final repo = ref.watch(tmdbRepositoryProvider);
  return repo.fetchTopRated();
});
