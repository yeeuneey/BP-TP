import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/tmdb_movie.dart';
import '../data/wishlist_repository.dart';

class WishlistAddButton extends ConsumerWidget {
  const WishlistAddButton({super.key, required this.movie});

  final TmdbMovie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(wishlistRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    return IconButton(
      icon: const Icon(Icons.favorite_border),
      onPressed: () async {
        final poster = movie.posterUrl(size: 'w342');
        try {
          await repo.add(movie.id, movie.title, poster);
          messenger.showSnackBar(
            const SnackBar(content: Text('Added to wishlist')),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      },
    );
  }
}
