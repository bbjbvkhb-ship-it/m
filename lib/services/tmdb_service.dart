import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  // Common TMDB API Key (v3 auth) for fetching generic metadata
  static const String _apiKey = '15d2ea6d0dc1d476efbca3eba2b9bbfb';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w200';

  // In-memory cache to prevent fetching the same actor's image multiple times
  static final Map<String, String?> _actorImageCache = {};
  // Cache for YouTube trailer keys
  static final Map<String, String?> _trailerKeyCache = {};

  /// Search for a person by name and return their profile image URL
  static Future<String?> getActorImageUrl(String actorName) async {
    // Return cached image if exists
    if (_actorImageCache.containsKey(actorName)) {
      return _actorImageCache[actorName];
    }

    try {
      final url = '$_baseUrl/search/person?api_key=$_apiKey&query=${Uri.encodeComponent(actorName)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final profilePath = data['results'][0]['profile_path'];
          if (profilePath != null) {
            final fullUrl = '$_imageBaseUrl$profilePath';
            _actorImageCache[actorName] = fullUrl;
            return fullUrl;
          }
        }
      }
    } catch (e) {
      print('Error fetching TMDB actor image for $actorName: $e');
    }

    // Cache null if not found so we don't retry endlessly
    _actorImageCache[actorName] = null;
    return null;
  }

  /// Search for a movie on TMDB by title (+ optional year) and return
  /// the YouTube video key of its official trailer — or null if not found.
  /// Results are cached so the same movie is never fetched twice.
  static Future<String?> getYoutubeTrailerKey(String title, {String? year}) async {
    final cacheKey = '$title|$year';
    if (_trailerKeyCache.containsKey(cacheKey)) {
      return _trailerKeyCache[cacheKey];
    }

    try {
      // 1️⃣  Search TMDB for the movie
      var searchUrl =
          '$_baseUrl/search/movie?api_key=$_apiKey&language=ar'
          '&query=${Uri.encodeComponent(title)}';
      if (year != null && year.isNotEmpty) searchUrl += '&year=$year';

      final searchRes = await http.get(Uri.parse(searchUrl));
      if (searchRes.statusCode != 200) {
        _trailerKeyCache[cacheKey] = null;
        return null;
      }

      final searchData = json.decode(searchRes.body);
      final results = searchData['results'] as List?;
      if (results == null || results.isEmpty) {
        _trailerKeyCache[cacheKey] = null;
        return null;
      }

      final movieId = results[0]['id'];

      // 2️⃣  Fetch the movie's videos (trailers)
      final videosUrl =
          '$_baseUrl/movie/$movieId/videos?api_key=$_apiKey&language=en-US';
      final videosRes = await http.get(Uri.parse(videosUrl));
      if (videosRes.statusCode != 200) {
        _trailerKeyCache[cacheKey] = null;
        return null;
      }

      final videosData = json.decode(videosRes.body);
      final videos = videosData['results'] as List?;
      if (videos == null || videos.isEmpty) {
        _trailerKeyCache[cacheKey] = null;
        return null;
      }

      // 3️⃣  Pick the best YouTube trailer/teaser
      final prioritized = [
        ...videos.where((v) =>
            v['site'] == 'YouTube' &&
            v['type'] == 'Trailer' &&
            v['official'] == true),
        ...videos.where((v) =>
            v['site'] == 'YouTube' && v['type'] == 'Trailer'),
        ...videos.where((v) =>
            v['site'] == 'YouTube' && v['type'] == 'Teaser'),
        ...videos.where((v) => v['site'] == 'YouTube'),
      ];

      final key = prioritized.isNotEmpty
          ? prioritized.first['key'] as String?
          : null;

      _trailerKeyCache[cacheKey] = key;
      return key;
    } catch (e) {
      print('Error fetching TMDB trailer key for "$title": $e');
      _trailerKeyCache[cacheKey] = null;
      return null;
    }
  }
}

