import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/tmdb_movie.dart';
import '../data/wishlist_repository.dart';

class WishlistAddButton extends ConsumerWidget {
  const WishlistAddButton({super.key, required this.movie});

  final TmdbMovie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.favorite_border),
      onPressed: () {
        final poster = movie.posterUrl(size: 'w342');
        ref
            .read(wishlistRepositoryProvider)
            .add(movie.id, movie.title, poster)
            .then((_) => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Added to wishlist'))))
            .catchError((e) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Failed: $e'))));
      },
    );
  }
}
