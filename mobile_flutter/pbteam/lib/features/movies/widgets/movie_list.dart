import 'package:flutter/material.dart';

import '../models/tmdb_movie.dart';

class MovieList extends StatelessWidget {
  const MovieList({super.key, required this.movies});

  final List<TmdbMovie> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
    );
  }
}
