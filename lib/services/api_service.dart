import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter/foundation.dart';
import '../models/movie.dart';

class ApiService {
  static const String baseUrl = 'https://movie.vodu.me';

  // Global headers to avoid getting blocked/throttled by Vodu CDNs
  static const Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Referer': 'https://movie.vodu.me/',
  };

  // Master helper to request high-definition crisp posters from Vodu CDNs
  String getHighResImageUrl(String url) {
    return _getHighResImageUrl(url);
  }

  static String _getHighResImageUrl(String url) {
    if (url.isEmpty) return url;
    // Replace default compressed thumbnail parameters with high-quality large size
    if (url.contains('?')) {
      final baseUrl = url.split('?')[0];
      return '$baseUrl?w=1000&h=1500&crop-to-fit&q=95';
    }
    return url;
  }

  Future<List<Movie>> fetchMovies() async {
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      if (response.statusCode == 200) {
        return await compute(_parseMoviesHtml, response.body);
      } else {
        throw Exception('Failed to load movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching movies: $e');
      return [];
    }
  }

  Future<Map<String, List<Movie>>> fetchCategorizedMovies() async {
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      if (response.statusCode == 200) {
        return await compute(_parseCategorizedMoviesHtml, response.body);
      }
    } catch (e) {
      debugPrint('Error fetching categorized movies: $e');
    }
    return {};
  }

  Future<Movie> fetchMovieDetails(String id, String defaultTitle, String defaultPoster) async {
    try {
      final url = '$baseUrl/index.php?do=view&type=post&id=$id';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return await compute(_parseMovieDetailsHtml, {
          'html': response.body,
          'id': id,
          'defaultTitle': defaultTitle,
          'defaultPoster': defaultPoster,
        });
      }
    } catch (e) {
      debugPrint('Error fetching movie details: $e');
    }
    return Movie(
      id: id,
      title: defaultTitle,
      posterUrl: defaultPoster,
      overview: 'فشل جلب تفاصيل الفيلم من المصدر، يرجى المحاولة لاحقاً.',
      rating: 0.0,
    );
  }

  Future<List<Movie>> searchMovies(String query) async {
    try {
      final url = '$baseUrl/index.php?do=list&title=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return await compute(_parseMoviesHtml, response.body);
      }
    } catch (e) {
      debugPrint('Error searching movies: $e');
    }
    return [];
  }

  Future<List<Movie>> fetchMoviesByType(String typeId) async {
    try {
      final url = '$baseUrl/index.php?do=list&type=$typeId';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return await compute(_parseMoviesHtml, response.body);
      }
    } catch (e) {
      debugPrint('Error fetching movies by type $typeId: $e');
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════
  // Static HTML Parsers for Background Isolates (compute)
  // ═══════════════════════════════════════════════════════

  static List<Movie> _parseMoviesHtml(String html) {
    final document = parser.parse(html);
    final myItems = document.querySelectorAll('.myitem');
    List<Movie> movies = [];

    for (var item in myItems) {
      final aElement = item.querySelector('a');
      if (aElement == null) continue;

      final href = aElement.attributes['href'] ?? '';
      if (!href.contains('id=')) continue;

      final idMatch = RegExp(r'id=(\d+)').firstMatch(href);
      final id = idMatch?.group(1) ?? '';

      final imgElement = item.querySelector('img');
      final String imgSrc = imgElement?.attributes['src'] ?? '';
      final rawPosterUrl = imgSrc.isNotEmpty
          ? (imgSrc.startsWith('http') ? imgSrc : '$baseUrl/$imgSrc')
          : 'https://via.placeholder.com/320x512.png?text=No+Image';

      final posterUrl = _getHighResImageUrl(rawPosterUrl);

      final titleElement = item.querySelector('.mytitle');
      final title = titleElement?.text.trim() ?? 'Unknown Title';

      if (title.isNotEmpty && id.isNotEmpty) {
        movies.add(Movie(
          id: id,
          title: title,
          posterUrl: posterUrl,
          overview: 'تفاصيل هذا المحتوى غير متوفرة حالياً.',
          rating: 0.0,
        ));
      }
    }
    return movies;
  }

  static Map<String, List<Movie>> _parseCategorizedMoviesHtml(String html) {
    final document = parser.parse(html);
    Map<String, List<Movie>> categories = {};
    final headerElements = document.querySelectorAll('h2');

    for (var header in headerElements) {
      final title = header.text.trim();
      if (title.isEmpty) continue;

      var nextEl = header.parent?.nextElementSibling;
      if (nextEl == null) continue;

      var homeseries = nextEl.querySelector('.homeseries');
      if (homeseries == null) {
        homeseries = nextEl.className.contains('homeseries') ? nextEl : null;
      }

      if (homeseries != null) {
        final myItems = homeseries.querySelectorAll('.myitem');
        List<Movie> movies = [];

        for (var item in myItems) {
          final aElement = item.querySelector('a');
          if (aElement == null) continue;

          final href = aElement.attributes['href'] ?? '';
          if (!href.contains('id=')) continue;

          final idMatch = RegExp(r'id=(\d+)').firstMatch(href);
          final id = idMatch?.group(1) ?? '';

          final imgElement = item.querySelector('img');
          final String imgSrc = imgElement?.attributes['src'] ?? '';
          final rawPosterUrl = imgSrc.isNotEmpty
              ? (imgSrc.startsWith('http') ? imgSrc : '$baseUrl/$imgSrc')
              : 'https://via.placeholder.com/320x512.png?text=No+Image';

          final posterUrl = _getHighResImageUrl(rawPosterUrl);

          final titleElement = item.querySelector('.mytitle');
          final movieTitle = titleElement?.text.trim() ?? 'Unknown Title';

          if (movieTitle.isNotEmpty && id.isNotEmpty) {
            movies.add(Movie(
              id: id,
              title: movieTitle,
              posterUrl: posterUrl,
              overview: 'تفاصيل هذا المحتوى غير متوفرة حالياً من القائمة الرئيسية.',
              rating: 0.0,
            ));
          }
        }
        if (movies.isNotEmpty) {
          categories[title] = movies;
        }
      }
    }

    if (categories.isEmpty) {
      final allMovies = _parseMoviesHtml(html);
      if (allMovies.isNotEmpty) {
        categories['أحدث الإضافات'] = allMovies;
      }
    }

    return categories;
  }

  static Movie _parseMovieDetailsHtml(Map<String, dynamic> params) {
    final html = params['html'] as String;
    final id = params['id'] as String;
    final defaultTitle = params['defaultTitle'] as String;
    final defaultPoster = params['defaultPoster'] as String;

    final document = parser.parse(html);

    final titleEl = document.querySelector('h1');
    final title = titleEl?.text.trim() ?? defaultTitle;

    final imgEl = document.querySelector('.col-md-4 img') ?? document.querySelector('.img-responsive');
    final imgSrc = imgEl?.attributes['src'] ?? '';
    final rawPosterUrl = imgSrc.isNotEmpty
        ? (imgSrc.startsWith('http') ? imgSrc : '$baseUrl/$imgSrc')
        : defaultPoster;

    final posterUrl = _getHighResImageUrl(rawPosterUrl);

    final playButton = document.querySelector('.play');
    // الرابط الكامل عالية الجودة للفيلم
    final videoUrl = playButton?.attributes['data-url1080'] ??
                     playButton?.attributes['data-url'] ?? '';

    // Extract all available video qualities for the movie
    final Map<String, String> qualities = {};
    if (playButton != null) {
      final url1080 = playButton.attributes['data-url1080'];
      final url720 = playButton.attributes['data-url720'];
      final url480 = playButton.attributes['data-url480'];
      final url360 = playButton.attributes['data-url360'];
      final defaultUrl = playButton.attributes['data-url'];

      if (url1080 != null && url1080.isNotEmpty) qualities['1080p'] = url1080;
      if (url720 != null && url720.isNotEmpty) qualities['720p'] = url720;
      if (url480 != null && url480.isNotEmpty) qualities['480p'] = url480;
      if (url360 != null && url360.isNotEmpty) qualities['360p'] = url360;
      if (defaultUrl != null && defaultUrl.isNotEmpty && !qualities.values.contains(defaultUrl)) {
        qualities['Default'] = defaultUrl;
      }
    }

    // التريلر: فقط نسخة -t.mp4 المنفصلة عن رابط 1080p
    String? trailerUrl;
    if (playButton != null) {
      final dataUrl   = playButton.attributes['data-url']   ?? '';
      final dataUrl1080 = playButton.attributes['data-url1080'] ?? '';
      // اعتبر الرابط تريلراً فقط إذا كان يحتوي على -t.mp4
      // وكان هناك رابط 1080p منفصل (يعني -t.mp4 ليس الفيلم الوحيد)
      final isTrailerUrl = dataUrl.contains('-t.mp4') ||
                           dataUrl.toLowerCase().contains('trailer');
      final hasSeparateFullMovie = dataUrl1080.isNotEmpty && dataUrl1080 != dataUrl;
      if (isTrailerUrl && hasSeparateFullMovie) {
        trailerUrl = dataUrl;
      }
    }

    // Extract Arabic subtitles for Movies (WebVTT or SRT)
    final subtitleUrl = playButton?.attributes['data-webvtt'] ??
                        playButton?.attributes['data-srt'] ?? '';

    String year = '2026';
    List<String> genres = [];
    double rating = 8.0;

    final h3s = document.querySelectorAll('h3');
    for (var h3 in h3s) {
      final text = h3.text;
      if (text.contains('Year:')) {
        year = text.replaceAll('Year:', '').trim();
      } else if (text.contains('Genre:')) {
        final genreStr = text.replaceAll('Genre:', '').trim();
        genres = genreStr.split('/').map((g) => g.trim()).toList();
      } else if (text.contains('IMdB Rating:')) {
        final ratingStr = text.replaceAll('IMdB Rating:', '').trim();
        rating = double.tryParse(ratingStr) ?? 8.0;
      }
    }

    String overview = 'لا يوجد قصة متوفرة لهذا الفيلم حالياً.';
    final h3List = document.querySelectorAll('h3');
    for (var h3 in h3List) {
      if (h3.text.contains('Synopsis:')) {
        var nextNode = h3.nextElementSibling;
        while (nextNode != null && nextNode.localName != 'h4') {
          nextNode = nextNode.nextElementSibling;
        }
        if (nextNode != null) {
          overview = nextNode.text.trim();
        }
        break;
      }
    }

    List<String> cast = [];
    final castEl = document.querySelector('.castxx');
    if (castEl != null) {
      final castStr = castEl.text.replaceAll('…', '').trim();
      cast = castStr.split('/').map((c) => c.trim()).toList();
    }

    String director = '';
    String writers = '';
    for (var h3 in h3s) {
      if (h3.text.trim() == 'Director') {
        var nextEl = h3.nextElementSibling;
        if (nextEl != null && nextEl.localName == 'h4') {
          director = nextEl.text.trim();
        }
      } else if (h3.text.trim() == 'Writers') {
        var nextEl = h3.nextElementSibling;
        if (nextEl != null && nextEl.localName == 'h4') {
          writers = nextEl.text.trim();
        }
      }
    }

    bool isSeasonOf(String current, String similar) {
      final cleanCurrent = current.toLowerCase().trim();
      final cleanSimilar = similar.toLowerCase().trim();

      if (cleanCurrent == cleanSimilar) return false;

      final hasSeasonKeyword = RegExp(
        r'(?:season|s\d+|الموسم|الجزء|part|ج\s*\d+)',
        caseSensitive: false,
      ).hasMatch(cleanSimilar);

      String getBaseName(String title) {
        return title
            .replaceAll(RegExp(r'(?:season|s\d+|الموسم|الجزء|part|ج|episode|ep)\s*\d*', caseSensitive: false), '')
            .replaceAll(RegExp(r'\d+$'), '')
            .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
            .trim();
      }

      final baseCurrent = getBaseName(cleanCurrent);
      final baseSimilar = getBaseName(cleanSimilar);

      if (baseCurrent.isEmpty || baseSimilar.isEmpty) return false;

      final baseMatch = baseCurrent == baseSimilar ||
          baseCurrent.startsWith(baseSimilar) ||
          baseSimilar.startsWith(baseCurrent);

      return baseMatch && (hasSeasonKeyword || RegExp(r'\d+$').hasMatch(cleanSimilar));
    }

    List<Movie> seasons = [];
    List<Episode> episodes = [];

    final tabElements = document.querySelectorAll('.nav-tabs .tabsx a');
    if (tabElements.isNotEmpty) {
      for (var tab in tabElements) {
        final seasonTitle = tab.text.trim();
        final href = tab.attributes['href'] ?? '';
        final tabId = href.startsWith('#') ? href.substring(1) : href;
        final tabDiv = document.getElementById(tabId) ?? document.querySelector('#$tabId');
        
        int? detectedSeason;
        final sMatch = RegExp(r'(?:Season|الموسم|الجزء|s|ج)\s*(\d+)', caseSensitive: false).firstMatch(seasonTitle);
        if (sMatch != null) {
          detectedSeason = int.tryParse(sMatch.group(1)!);
        }
        detectedSeason ??= seasons.length + 1;

        List<Episode> seasonEpisodes = [];
        if (tabDiv != null) {
          final epItems = tabDiv.querySelectorAll('.episodeitem');
          int epCounter = 0;
          for (var ep in epItems) {
            final playBtn = ep.querySelector('.play');
            if (playBtn != null) {
              epCounter++;
              final epTitle = playBtn.attributes['data-title'] ??
                              ep.querySelector('.col-md-7')?.text.trim() ?? 'Episode';
              final epUrl = playBtn.attributes['data-url1080'] ??
                            playBtn.attributes['data-url'] ?? '';
              final epSize = ep.querySelector('.col-md-2')?.text.trim() ?? '';
              
              int? epNumber;
              final numMatch = RegExp(r'(?:episode|ep\.?|الحلقة|حلقة)?\s*(\d+)', caseSensitive: false).firstMatch(epTitle);
              if (numMatch != null) {
                epNumber = int.tryParse(numMatch.group(1)!);
              }
              epNumber ??= epCounter;

              final epSubUrl = playBtn.attributes['data-webvtt'] ??
                               playBtn.attributes['data-srt'] ?? '';

              final Map<String, String> epQualities = {};
              final url1080 = playBtn.attributes['data-url1080'];
              final url720 = playBtn.attributes['data-url720'];
              final url480 = playBtn.attributes['data-url480'];
              final url360 = playBtn.attributes['data-url360'];
              final defaultUrl = playBtn.attributes['data-url'];

              if (url1080 != null && url1080.isNotEmpty) epQualities['1080p'] = url1080;
              if (url720 != null && url720.isNotEmpty) epQualities['720p'] = url720;
              if (url480 != null && url480.isNotEmpty) epQualities['480p'] = url480;
              if (url360 != null && url360.isNotEmpty) epQualities['360p'] = url360;
              if (defaultUrl != null && defaultUrl.isNotEmpty && !epQualities.values.contains(defaultUrl)) {
                epQualities['Default'] = defaultUrl;
              }

              // استخراج صورة مصغّرة للحلقة (thumbnail)
              String? epThumbUrl;
              final epThumb = playBtn.attributes['data-thumbnail'] ??
                              playBtn.attributes['data-thumb'] ??
                              playBtn.attributes['data-poster'] ??
                              playBtn.attributes['data-image'];
              if (epThumb != null && epThumb.isNotEmpty) {
                epThumbUrl = epThumb.startsWith('http') ? epThumb : '$baseUrl/$epThumb';
              } else {
                final epImg = ep.querySelector('img');
                final epImgSrc = epImg?.attributes['src'] ?? epImg?.attributes['data-src'] ?? '';
                if (epImgSrc.isNotEmpty) {
                  epThumbUrl = epImgSrc.startsWith('http') ? epImgSrc : '$baseUrl/$epImgSrc';
                }
              }

              if (epUrl.isNotEmpty) {
                seasonEpisodes.add(Episode(
                  title: epTitle,
                  videoUrl: epUrl,
                  fileSize: epSize,
                  subtitleUrl: epSubUrl,
                  videoQualities: epQualities,
                  episodeNumber: epNumber,
                  seasonNumber: detectedSeason,
                  thumbnailUrl: epThumbUrl,
                ));
              }
            }
          }
        }

        seasons.add(Movie(
          id: '$id-season-$detectedSeason',
          title: seasonTitle,
          posterUrl: posterUrl,
          seasonNumber: detectedSeason,
          isSeries: true,
          episodes: seasonEpisodes,
        ));
      }
    }

    if (seasons.isEmpty) {
      final epItems = document.querySelectorAll('.episodeitem');
      int epCounter = 0;
      for (var ep in epItems) {
        final playBtn = ep.querySelector('.play');
        if (playBtn != null) {
          epCounter++;
          final epTitle = playBtn.attributes['data-title'] ??
                          ep.querySelector('.col-md-7')?.text.trim() ?? 'Episode';
          final epUrl = playBtn.attributes['data-url1080'] ??
                        playBtn.attributes['data-url'] ?? '';
          final epSize = ep.querySelector('.col-md-2')?.text.trim() ?? '';
          
          int? epNumber;
          final numMatch = RegExp(r'(?:episode|ep\.?|الحلقة|حلقة)?\s*(\d+)', caseSensitive: false).firstMatch(epTitle);
          if (numMatch != null) {
            epNumber = int.tryParse(numMatch.group(1)!);
          }
          epNumber ??= epCounter;

          final epSubUrl = playBtn.attributes['data-webvtt'] ??
                           playBtn.attributes['data-srt'] ?? '';

          final Map<String, String> epQualities = {};
          final url1080 = playBtn.attributes['data-url1080'];
          final url720 = playBtn.attributes['data-url720'];
          final url480 = playBtn.attributes['data-url480'];
          final url360 = playBtn.attributes['data-url360'];
          final defaultUrl = playBtn.attributes['data-url'];

          if (url1080 != null && url1080.isNotEmpty) epQualities['1080p'] = url1080;
          if (url720 != null && url720.isNotEmpty) epQualities['720p'] = url720;
          if (url480 != null && url480.isNotEmpty) epQualities['480p'] = url480;
          if (url360 != null && url360.isNotEmpty) epQualities['360p'] = url360;
          if (defaultUrl != null && defaultUrl.isNotEmpty && !epQualities.values.contains(defaultUrl)) {
            epQualities['Default'] = defaultUrl;
          }

          // استخراج صورة مصغّرة للحلقة
          String? epThumbUrl;
          final epThumb = playBtn.attributes['data-thumbnail'] ??
                          playBtn.attributes['data-thumb'] ??
                          playBtn.attributes['data-poster'] ??
                          playBtn.attributes['data-image'];
          if (epThumb != null && epThumb.isNotEmpty) {
            epThumbUrl = epThumb.startsWith('http') ? epThumb : '$baseUrl/$epThumb';
          } else {
            final epImg = ep.querySelector('img');
            final epImgSrc = epImg?.attributes['src'] ?? epImg?.attributes['data-src'] ?? '';
            if (epImgSrc.isNotEmpty) {
              epThumbUrl = epImgSrc.startsWith('http') ? epImgSrc : '$baseUrl/$epImgSrc';
            }
          }

          if (epUrl.isNotEmpty) {
            episodes.add(Episode(
              title: epTitle,
              videoUrl: epUrl,
              fileSize: epSize,
              subtitleUrl: epSubUrl,
              videoQualities: epQualities,
              episodeNumber: epNumber,
              thumbnailUrl: epThumbUrl,
            ));
          }
        }
      }
      
      if (episodes.isNotEmpty) {
        seasons.add(Movie(
          id: id,
          title: 'الموسم 01',
          posterUrl: posterUrl,
          seasonNumber: 1,
          isSeries: true,
          episodes: episodes,
        ));
      }
    }

    List<Movie> similarMovies = [];
    final homeseries = document.querySelector('.homeseries');
    if (homeseries != null) {
      final myItems = homeseries.querySelectorAll('.myitem');
      int seasonCounter = 1;
      for (var item in myItems) {
        final aElement = item.querySelector('a');
        if (aElement == null) continue;

        final href = aElement.attributes['href'] ?? '';
        if (!href.contains('id=')) continue;

        final idMatch = RegExp(r'id=(\d+)').firstMatch(href);
        final simId = idMatch?.group(1) ?? '';

        final imgElement = item.querySelector('img');
        final String imgSrc = imgElement?.attributes['src'] ?? '';
        final rawSimPoster = imgSrc.isNotEmpty
            ? (imgSrc.startsWith('http') ? imgSrc : '$baseUrl/$imgSrc')
            : 'https://via.placeholder.com/320x512.png?text=No+Image';

        final simPoster = _getHighResImageUrl(rawSimPoster);

        final titleElement = item.querySelector('.mytitle');
        final simTitle = titleElement?.text.trim() ?? 'Unknown Title';

        if (simTitle.isNotEmpty && simId.isNotEmpty) {
          int? detectedSeason;
          final sMatch = RegExp(
            r'(?:الجزء|الموسم|season|s)\s*(\d+)',
            caseSensitive: false,
          ).firstMatch(simTitle);
          if (sMatch != null) {
            detectedSeason = int.tryParse(sMatch.group(1)!);
          } else {
            final numMatch = RegExp(r'(\d+)\s*$').firstMatch(simTitle);
            detectedSeason = numMatch != null
                ? int.tryParse(numMatch.group(1)!)
                : seasonCounter;
          }
          detectedSeason ??= seasonCounter;
          seasonCounter++;

          final simMovie = Movie(
            id: simId,
            title: simTitle,
            posterUrl: simPoster,
            seasonNumber: detectedSeason,
            isSeries: tabElements.isNotEmpty || episodes.isNotEmpty,
          );

          if (isSeasonOf(title, simTitle)) {
            final alreadyExists = seasons.any((s) => s.id == simId || s.seasonNumber == detectedSeason);
            if (!alreadyExists) {
              seasons.add(simMovie);
            }
          } else {
            similarMovies.add(simMovie);
          }
        }
      }
    }

    if (seasons.isNotEmpty) {
      seasons.sort((a, b) => (a.seasonNumber ?? 0).compareTo(b.seasonNumber ?? 0));
    }

    final isSeries = tabElements.isNotEmpty || episodes.isNotEmpty || (seasons.isNotEmpty && seasons.any((s) => s.episodes != null && s.episodes!.isNotEmpty));
    final defaultEpisodes = episodes.isNotEmpty 
        ? episodes 
        : (seasons.isNotEmpty ? (seasons.first.episodes ?? []) : <Episode>[]);

    int? currentSeasonNum;
    final csMatch = RegExp(
      r'(?:الجزء|الموسم|season|s)\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(title);
    if (csMatch != null) {
      currentSeasonNum = int.tryParse(csMatch.group(1)!);
    }

    return Movie(
      id: id,
      title: title,
      posterUrl: posterUrl,
      overview: overview,
      rating: rating,
      year: year,
      genres: genres,
      videoUrl: videoUrl,
      cast: cast,
      similarMovies: similarMovies.isNotEmpty ? similarMovies : null,
      seasons: seasons.isNotEmpty ? seasons : null,
      director: director,
      writers: writers,
      episodes: defaultEpisodes,
      subtitleUrl: subtitleUrl,
      trailerUrl: trailerUrl,
      videoQualities: qualities,
      isSeries: isSeries,
      seasonNumber: currentSeasonNum,
    );
  }
}
