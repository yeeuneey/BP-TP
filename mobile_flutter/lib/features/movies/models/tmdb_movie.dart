class TmdbMovie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final int? runtime;
  final List<int> genreIds;
  final List<String> genres;
  final String? language;
  final String? country;

  const TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.runtime,
    required this.genreIds,
    required this.genres,
    required this.language,
    required this.country,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'] as List<dynamic>?;
    final genreNames = rawGenres == null
        ? const <String>[]
        : rawGenres
            .map((e) => (e as Map<String, dynamic>?)?['name'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
    String? country;
    final productionCountries = json['production_countries'] as List<dynamic>?;
    if (productionCountries != null && productionCountries.isNotEmpty) {
      for (final entry in productionCountries) {
        if (entry is Map<String, dynamic>) {
          country = (entry['name'] as String?) ??
              (entry['iso_3166_1'] as String?)?.toUpperCase();
        }
        if (country != null && country.isNotEmpty) break;
      }
    }
    if (country == null || country.isEmpty) {
      final origin = json['origin_country'] as List<dynamic>?;
      if (origin != null && origin.isNotEmpty) {
        final first = origin.firstWhere(
          (e) => e is String && e.isNotEmpty,
          orElse: () => null,
        );
        if (first is String) {
          country = first.toUpperCase();
        }
      }
    }
    return TmdbMovie(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      runtime: (json['runtime'] as num?)?.toInt(),
      genreIds: (json['genre_ids'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      genres: genreNames,
      language: (json['original_language'] as String?)?.toUpperCase(),
      country: country,
    );
  }

  String posterUrl({String size = 'w500'}) {
    if (posterPath == null) return '';
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }

  TmdbMovie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    double? voteAverage,
    int? voteCount,
    int? runtime,
    List<int>? genreIds,
    List<String>? genres,
    String? language,
    String? country,
  }) {
    return TmdbMovie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      runtime: runtime ?? this.runtime,
      genreIds: genreIds ?? this.genreIds,
      genres: genres ?? this.genres,
      language: language ?? this.language,
      country: country ?? this.country,
    );
  }

  /// Merge detail payload into a list item, preferring richer fields.
  TmdbMovie merge(TmdbMovie detail) {
    return copyWith(
      title: detail.title.isNotEmpty ? detail.title : null,
      overview: detail.overview.isNotEmpty ? detail.overview : null,
      posterPath: detail.posterPath ?? posterPath,
      backdropPath: detail.backdropPath ?? backdropPath,
      releaseDate: detail.releaseDate ?? releaseDate,
      voteAverage: detail.voteAverage != 0 ? detail.voteAverage : voteAverage,
      voteCount: detail.voteCount != 0 ? detail.voteCount : voteCount,
      runtime: detail.runtime ?? runtime,
      genreIds: detail.genreIds.isNotEmpty ? detail.genreIds : genreIds,
      genres: detail.genres.isNotEmpty ? detail.genres : genres,
      language: detail.language ?? language,
      country: detail.country ?? country,
    );
  }
}
