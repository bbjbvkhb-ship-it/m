import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Movie> _movies = [];
  Map<String, List<Movie>> _categories = {};
  bool _isLoading = false;
  String _selectedTheme = 'tv_plus'; // Default theme is TV Plus

  MovieProvider() {
    _loadTheme();
  }

  List<Movie> get movies => _movies;
  Map<String, List<Movie>> get categories => _categories;
  bool get isLoading => _isLoading;
  String get selectedTheme => _selectedTheme;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedTheme = prefs.getString('selected_theme') ?? 'tv_plus';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(String theme) async {
    if (_selectedTheme == theme) return;
    _selectedTheme = theme;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_theme', theme);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // Load categories progressively:
  // 1. Load first two categories immediately → show content fast
  // 2. Load remaining categories in background
  // ─────────────────────────────────────────────────────────
  Future<void> loadMovies() async {
    if (_isLoading) return; // guard against double-calls
    _isLoading = true;
    notifyListeners();

    // Priority categories shown first
    final priorityTypes = [
      ('أفلام أجنبية', '0'),
      ('مسلسلات أجنبية', '1'),
    ];

    // Remaining categories loaded after first paint
    final remainingTypes = [
      ('أفلام عربية', '7'),
      ('أفلام تركية', '14'),
      ('مسلسلات عربية', '4'),
      ('مسلسلات تركية', '15'),
      ('مسلسلات أنمي', '2'),
    ];

    try {
      // ── Step 1: Load first two categories in parallel ──
      final priority = await Future.wait(
        priorityTypes.map((t) => _apiService.fetchMoviesByType(t.$2)),
      );

      for (int i = 0; i < priorityTypes.length; i++) {
        if (priority[i].isNotEmpty) {
          _categories[priorityTypes[i].$1] = priority[i];
        }
      }

      _movies = _categories.values.isNotEmpty ? _categories.values.first : [];
      _isLoading = false;
      notifyListeners(); // ← First paint with priority content

      // ── Step 2: Load remaining categories in background ──
      _loadRemainingCategories(remainingTypes);
    } catch (e) {
      debugPrint('Error loading priority categories: $e');
      // Fallback: try fetching all at once
      try {
        _categories = await _apiService.fetchCategorizedMovies();
        _movies = _categories.values.isNotEmpty ? _categories.values.first : [];
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRemainingCategories(
      List<(String, String)> types) async {
    // Small delay to not compete with first render
    await Future.delayed(const Duration(milliseconds: 800));

    for (final (name, typeId) in types) {
      try {
        final movies = await _apiService.fetchMoviesByType(typeId);
        if (movies.isNotEmpty) {
          _categories[name] = movies;
          notifyListeners(); // Update UI as each category arrives
        }
      } catch (e) {
        debugPrint('Error loading $name: $e');
      }
    }
  }
}
