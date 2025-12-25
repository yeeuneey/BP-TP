import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tmdb_repository.dart';
import '../models/tmdb_movie.dart';

final movieDetailProvider =
    FutureProvider.family<TmdbMovie, int>((ref, id) async {
  final repo = ref.watch(tmdbRepositoryProvider);
  return repo.fetchDetails(id);
});
