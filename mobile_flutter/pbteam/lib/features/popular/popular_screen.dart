import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../movies/providers/popular_provider.dart';

class PopularScreen extends ConsumerWidget {
  const PopularScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularMoviesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Popular')),
      body: popularAsync.when(
        data: (movies) => ListView.separated(
          itemCount: movies.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = movies[index];
            return ListTile(
              leading: m.posterPath != null
                  ? Image.network(m.posterUrl(size: 'w154'), width: 50, fit: BoxFit.cover)
                  : const SizedBox(width: 50),
              title: Text(m.title),
              subtitle: Text(m.overview, maxLines: 2, overflow: TextOverflow.ellipsis),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
