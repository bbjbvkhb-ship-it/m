import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  List<Movie> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Suggestion & Trending Movies data structures
  List<Movie> _trendingMovies = [];
  bool _isTrendingLoading = false;
  
  final List<String> _popularSuggestions = [
    'أكشن 💥',
    'دراما 🎭',
    'غموض 🔍',
    'رعب 💀',
    'خيال علمي 🛸',
    'كوميدي 😂',
    'أنمي ⛩️',
    'مارفل 🦸',
    'ديزني 🏰',
    'إثارة ⚡',
  ];

  final Map<String, String> _suggestionSearchTerms = {
    'أكشن 💥': 'Action',
    'دراما 🎭': 'Drama',
    'غموض 🔍': 'Mystery',
    'رعب 💀': 'Horror',
    'خيال علمي 🛸': 'Sci-Fi',
    'كوميدي 😂': 'Comedy',
    'أنمي ⛩️': 'Anime',
    'مارفل 🦸': 'Marvel',
    'ديزني 🏰': 'Disney',
    'إثارة ⚡': 'Thriller',
  };

  @override
  void initState() {
    super.initState();
    _loadTrendingMovies();

    // Intercept Arrow Down key in search bar to move focus to results
    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowDown) {
          FocusScope.of(context).nextFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingMovies() async {
    if (!mounted) return;
    setState(() {
      _isTrendingLoading = true;
    });
    try {
      final movies = await _apiService.fetchMovies();
      if (!mounted) return;
      setState(() {
        _trendingMovies = movies;
      });
    } catch (e) {
      print('Error loading trending movies in search: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTrendingLoading = false;
        });
      }
    }
  }

  // Design Tokens (Tailwind Cinema Harmony)
  static const Color background = Color(0xFF141414);
  static const Color primary = Color(0xFF00E5FF);
  static const Color onSurface = Color(0xFFF0EFFF);
  static const Color onSurfaceVariant = Color(0xFFA59EC6);

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    final results = await _apiService.searchMovies(query);

    // Discard stale results if the user typed something else while fetching
    if (!mounted || _searchController.text.trim() != query.trim()) return;

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });

    if (results.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.nextFocus();
        }
      });
    }
  }

  Widget _buildGlassPanel({required Widget child, double borderRadius = 12, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: primary, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ابحث',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Glassmorphic Search Bar
              _buildGlassPanel(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: const TextStyle(color: onSurface, fontSize: 18, fontFamily: 'Cairo'),
                  cursorColor: primary,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) {
                    _performSearch(query);
                    _searchFocusNode.nextFocus();
                  },
                  onChanged: (query) {
                    setState(() {}); // Update the clear button visibility instantly
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 600), () {
                      _performSearch(query);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن فيلم، مسلسل، أو أنمي...',
                    hintStyle: const TextStyle(color: onSurfaceVariant, fontSize: 16, fontFamily: 'Cairo'),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded, color: primary, size: 26),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              setState(() {}); // Update the clear button visibility instantly
                              _performSearch('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status / Results header
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                )
              else if (_searchResults.isEmpty && _searchQuery.isNotEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'لم نجد نتائج مطابقة لبحثك 😕',
                      style: TextStyle(color: onSurfaceVariant, fontSize: 18, fontFamily: 'Cairo'),
                    ),
                  ),
                )
              else if (_searchResults.isEmpty && _searchQuery.isEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Popular Suggestions Section
                        const Text(
                          'اقتراحات شائعة 🔥',
                          style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _popularSuggestions.map((tag) {
                            return _SuggestionChip(
                              label: tag,
                              onTap: (selectedTag) {
                                final searchTerm = _suggestionSearchTerms[selectedTag] ?? selectedTag;
                                _searchController.text = selectedTag;
                                _performSearch(searchTerm);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Trending Movies Section
                        const Text(
                          'الأفلام الرائجة الآن ⚡',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_isTrendingLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: CircularProgressIndicator(color: primary),
                            ),
                          )
                        else if (_trendingMovies.isEmpty)
                          const Center(
                            child: Text(
                              'لا توجد اقتراحات حالياً.',
                              style: TextStyle(color: onSurfaceVariant, fontSize: 14, fontFamily: 'Cairo'),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final isDesktopOrTV = width >= 700;
                              final targetWidth = isDesktopOrTV ? 280 : 180;
                              int crossAxisCount = (width / targetWidth).floor();
                              if (crossAxisCount < 2) crossAxisCount = 2;
                              final childAspectRatio = isDesktopOrTV ? 1.25 : 1.15;
                              
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _trendingMovies.take(12).length,
                                itemBuilder: (context, index) {
                                  final movie = _trendingMovies[index];
                                  return Center(
                                    child: MovieCard(
                                      movie: movie,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailsScreen(movie: movie),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            }
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نتائج البحث عن "$_searchQuery":',
                        style: const TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                             final width = constraints.maxWidth;
                             final isDesktopOrTV = width >= 700;
                             final targetWidth = isDesktopOrTV ? 280 : 180;
                             int crossAxisCount = (width / targetWidth).floor();
                             if (crossAxisCount < 2) crossAxisCount = 2;
                             final childAspectRatio = isDesktopOrTV ? 1.25 : 1.15;

                             return GridView.builder(
                               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                 crossAxisCount: crossAxisCount,
                                 childAspectRatio: childAspectRatio, // Exact matching poster ratio to prevent squashing
                                 crossAxisSpacing: 12,
                                 mainAxisSpacing: 12,
                               ),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final movie = _searchResults[index];
                                return Center(
                                  child: MovieCard(
                                    movie: movie,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailsScreen(movie: movie),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String label;
  final ValueChanged<String> onTap;

  const _SuggestionChip({Key? key, required this.label, required this.onTap}) : super(key: key);

  @override
  __SuggestionChipState createState() => __SuggestionChipState();
}

class __SuggestionChipState extends State<_SuggestionChip> {
  bool _isFocused = false;
  bool _isHovered = false;

  bool get _isHighlighted => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter || 
              key == LogicalKeyboardKey.select || 
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space) {
            widget.onTap(widget.label);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.label),
          child: AnimatedScale(
            scale: _isHighlighted ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isHighlighted 
                    ? const Color(0xFF00E5FF).withOpacity(0.15) 
                    : const Color(0xFF13112B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _isHighlighted 
                      ? const Color(0xFF00E5FF) 
                      : Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
                boxShadow: _isHighlighted ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: _isHighlighted ? const Color(0xFF00E5FF) : const Color(0xFFF0EFFF),
                  fontWeight: _isHighlighted ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
