import 'package:flutter/material.dart';

import '../models/tmdb_movie.dart';

class MovieMeta extends StatelessWidget {
  const MovieMeta({super.key, required this.movie});

  final TmdbMovie movie;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (movie.releaseDate != null)
          _chip(Icons.calendar_today, movie.releaseDate!),
        _chip(Icons.star, movie.voteAverage.toStringAsFixed(1)),
        if (movie.genreIds.isNotEmpty)
          _chip(Icons.category, '${movie.genreIds.length} genres'),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
