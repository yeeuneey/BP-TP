import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../movies/providers/popular_provider.dart';
import '../movies/widgets/movie_list.dart';

class PopularScreen extends ConsumerWidget {
  const PopularScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularMoviesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Popular')),
      body: popularAsync.when(
        data: (movies) => MovieList(movies: movies),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
