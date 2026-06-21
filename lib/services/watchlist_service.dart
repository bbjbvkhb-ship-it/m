import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// بيانات المسلسل المتابَع المحفوظة محلياً
class WatchedSeries {
  final String id;
  final String title;
  final String posterUrl;
  final int episodeCount; // عدد الحلقات وقت الإضافة

  WatchedSeries({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.episodeCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'posterUrl': posterUrl,
        'episodeCount': episodeCount,
      };

  factory WatchedSeries.fromJson(Map<String, dynamic> json) => WatchedSeries(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        posterUrl: json['posterUrl'] ?? '',
        episodeCount: json['episodeCount'] ?? 0,
      );

  WatchedSeries copyWith({int? episodeCount}) => WatchedSeries(
        id: id,
        title: title,
        posterUrl: posterUrl,
        episodeCount: episodeCount ?? this.episodeCount,
      );
}

class WatchlistService {
  static const String _key = 'watchlist_series';
  static const int maxItems = 20;

  /// جلب قائمة المتابَعة
  static Future<List<WatchedSeries>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try {
        return WatchedSeries.fromJson(jsonDecode(s));
      } catch (_) {
        return null;
      }
    }).whereType<WatchedSeries>().toList();
  }

  /// هل المسلسل مضاف للمتابَعة؟
  static Future<bool> isFollowing(String seriesId) async {
    final list = await getWatchlist();
    return list.any((s) => s.id == seriesId);
  }

  /// إضافة مسلسل للمتابَعة (بحد أقصى 5)
  /// يعيد true إذا نجحت الإضافة, false إذا وصلنا للحد الأقصى
  static Future<bool> addToWatchlist(WatchedSeries series) async {
    final list = await getWatchlist();
    if (list.any((s) => s.id == series.id)) return true; // موجود بالفعل
    if (list.length >= maxItems) return false; // وصلنا للحد الأقصى
    list.add(series);
    await _save(list);
    return true;
  }

  /// إزالة مسلسل من المتابَعة
  static Future<void> removeFromWatchlist(String seriesId) async {
    final list = await getWatchlist();
    list.removeWhere((s) => s.id == seriesId);
    await _save(list);
  }

  /// تحديث عدد الحلقات بعد اكتشاف حلقة جديدة
  static Future<void> updateEpisodeCount(String seriesId, int newCount) async {
    final list = await getWatchlist();
    final idx = list.indexWhere((s) => s.id == seriesId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(episodeCount: newCount);
      await _save(list);
    }
  }

  static Future<void> _save(List<WatchedSeries> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list.map((s) => jsonEncode(s.toJson())).toList());
  }
}
