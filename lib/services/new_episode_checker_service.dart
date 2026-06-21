import '../services/api_service.dart';
import '../services/watchlist_service.dart';

class NewEpisodeResult {
  final WatchedSeries series;
  final int oldCount;
  final int newCount;
  final int newEpisodeNumber;

  NewEpisodeResult({
    required this.series,
    required this.oldCount,
    required this.newCount,
    required this.newEpisodeNumber,
  });
}

class NewEpisodeCheckerService {
  static final ApiService _api = ApiService();

  /// يفحص كل المسلسلات المتابَعة ويعيد قائمة بمن لديه حلقات جديدة (بالتوازي لتسريع العملية)
  static Future<List<NewEpisodeResult>> checkForNewEpisodes() async {
    final watchlist = await WatchlistService.getWatchlist();
    if (watchlist.isEmpty) return [];
    
    final results = <NewEpisodeResult>[];

    try {
      final futures = watchlist.map((series) async {
        try {
          final detailed = await _api.fetchMovieDetails(
            series.id,
            series.title,
            series.posterUrl,
          );
          final newCount = detailed.episodes?.length ?? 0;
          if (newCount > series.episodeCount && series.episodeCount > 0) {
            results.add(NewEpisodeResult(
              series: series,
              oldCount: series.episodeCount,
              newCount: newCount,
              newEpisodeNumber: newCount,
            ));
            // نحدث العدد المحفوظ حتى لا يظهر المودل مجدداً
            await WatchlistService.updateEpisodeCount(series.id, newCount);
          } else if (series.episodeCount == 0 && newCount > 0) {
            // أول مرة نجلب عدد الحلقات, نحفظها بدون إظهار مودل
            await WatchlistService.updateEpisodeCount(series.id, newCount);
          }
        } catch (e) {
          print('Error checking episode updates for ${series.title}: $e');
        }
      }).toList();

      await Future.wait(futures);
    } catch (e) {
      print('Error in parallel episode check: $e');
    }

    return results;
  }
}
