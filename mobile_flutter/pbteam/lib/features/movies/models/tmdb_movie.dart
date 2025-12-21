class TmdbMovie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final List<String> genres;
  final String? language;

  const TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.genreIds,
    required this.genres,
    required this.language,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'] as List<dynamic>?;
    final genreNames = rawGenres == null
        ? const <String>[]
        : rawGenres
            .map((e) => (e as Map<String, dynamic>?)?['name'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
    return TmdbMovie(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      genres: genreNames,
      language: (json['original_language'] as String?)?.toUpperCase(),
    );
  }

  String posterUrl({String size = 'w500'}) {
    if (posterPath == null) return '';
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }
}
