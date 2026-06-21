class Episode {
  final String title;
  final String videoUrl;
  final String fileSize;
  final String? subtitleUrl;
  final Map<String, String>? videoQualities;
  final int? episodeNumber;
  final int? seasonNumber;
  final String? thumbnailUrl;
  final int? durationSeconds; // مدة الحلقة بالثواني

  Episode({
    required this.title,
    required this.videoUrl,
    required this.fileSize,
    this.subtitleUrl,
    this.videoQualities,
    this.episodeNumber,
    this.seasonNumber,
    this.thumbnailUrl,
    this.durationSeconds,
  });
}

class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final String? overview;
  final double? rating;
  final String? year;
  final List<String>? genres;
  final String? videoUrl;
  final List<String>? cast;
  final List<Movie>? similarMovies; // مسلسلات/أفلام مشابهة
  final List<Movie>? seasons;       // مواسم المسلسل (مُستخلصة من similarMovies)
  final String? director;
  final String? writers;
  final List<Episode>? episodes;
  final String? subtitleUrl;
  final String? trailerUrl;
  final Map<String, String>? videoQualities;
  final bool isSeries; // هل هو مسلسل أم فيلم؟
  final int? seasonNumber; // رقم الموسم إن كان مسلسلاً

  Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    this.overview,
    this.rating,
    this.year,
    this.genres,
    this.videoUrl,
    this.cast,
    this.similarMovies,
    this.seasons,
    this.director,
    this.writers,
    this.episodes,
    this.subtitleUrl,
    this.trailerUrl,
    this.videoQualities,
    this.isSeries = false,
    this.seasonNumber,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Title',
      posterUrl: json['poster'] ?? '',
      overview: json['overview'] ?? '',
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : 0.0,
    );
  }
}
