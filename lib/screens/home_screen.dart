import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import 'details_screen.dart';
import 'search_screen.dart';
import 'player_screen.dart';
import '../widgets/tv_plus_logos.dart';
import '../services/new_episode_checker_service.dart';
import '../widgets/new_episode_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _selectedCategoryType = 'all';
  List<Movie> _categoryMovies = [];
  bool _isCategoryLoading = false;

  Movie? _heroMovie;
  VideoPlayerController? _heroVideoController;
  Timer? _heroVideoTimer;

  // Selected subcategory for live TV channels
  String _selectedLiveSubcategory = 'all';

  final ScrollController _mainScrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
    _searchFocusNode.dispose();
    _heroVideoTimer?.cancel();
    _heroVideoController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_mainScrollController.hasClients) return;
    final offset = _mainScrollController.offset;
    if (offset > 450) {
      if (_heroVideoController != null && _heroVideoController!.value.isPlaying) {
        _heroVideoController!.pause();
      }
    } else {
      if (_heroVideoController != null && !_heroVideoController!.value.isPlaying && _selectedCategoryType != 'live_tv') {
        _heroVideoController!.play();
      }
    }
  }

  /// Scrolls to the top and moves focus to the search button in the AppBar.
  void _focusSearchBar() {
    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    _searchFocusNode.requestFocus();
  }

  void _pauseHeroVideo() {
    _heroVideoTimer?.cancel();
    _heroVideoController?.pause();
  }

  void _resumeHeroVideo() {
    if (_heroMovie != null && _heroVideoController != null && !_heroVideoController!.value.isPlaying) {
      _heroVideoController!.play();
    }
  }

  void _updateHeroMovie(Movie movie) {
    if (_heroMovie?.id == movie.id && _heroVideoController != null) return;
    
    _heroVideoTimer?.cancel();
    _heroVideoController?.pause();
    _heroVideoController?.dispose();
    _heroVideoController = null;

    _heroVideoTimer = Timer(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;
      try {
        final fullDetails = await _apiService.fetchMovieDetails(movie.id, movie.title, movie.posterUrl);
        if (!mounted) return;

        setState(() {
          _heroMovie = fullDetails;
        });

        if (fullDetails.trailerUrl != null && fullDetails.trailerUrl!.isNotEmpty) {
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(fullDetails.trailerUrl!),
            httpHeaders: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
              'Referer': 'https://movie.vodu.me/',
            },
          );
          controller.initialize().then((_) {
            if (!mounted) return;
            controller.setVolume(0.0);
            controller.setLooping(true);
            // Only play if we are still on this screen (not paused)
            if (_heroVideoController == null) {
              controller.play();
              setState(() {
                _heroVideoController = controller;
              });
            } else {
              controller.dispose();
            }
          });
        }
      } catch (e) {
        print("Error playing hero trailer: $e");
      }
    });
  }

  // Design tokens from code.html
  static const Color background = Color(0xFF141414);
  static const Color primary = Color(0xFF00E5FF);
  static const Color onPrimary = Color(0xFF00373F);
  static const Color onSurface = Color(0xFFF0EFFF);
  static const Color onSurfaceVariant = Color(0xFFA59EC6);
  static const Color surfaceContainerHigh = Color(0xFF13112B);


  // Main Sidebar Categories list
  final List<Map<String, String>> _mainCategories = [
    {'name': 'الرئيسية', 'type': 'all'},
    {'name': 'البث المباشر', 'type': 'live_tv'},
    {'name': 'أفلام أجنبية', 'type': '0'},
    {'name': 'أفلام عربية', 'type': '7'},
    {'name': 'أفلام تركية', 'type': '14'},
    {'name': 'مسلسلات أجنبية', 'type': '1'},
    {'name': 'مسلسلات عربية', 'type': '4'},
    {'name': 'مسلسلات تركية', 'type': '15'},
    {'name': 'أفلام أنمي', 'type': '9'},
    {'name': 'مسلسلات أنمي', 'type': '2'},
    {'name': 'أفلام كرتون', 'type': '16'},
    {'name': 'مسلسلات كرتون', 'type': '17'},
    {'name': 'بوكس أوفيس', 'type': '10'},
  ];

  // List of official Live TV channels mapped to local assets
  final List<Map<String, String>> _liveChannels = [
    // beIN Sports
    {
      'name': 'beIN Sports 1 HD',
      'url': 'http://10.3.0.4/Bein-Sport-1/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/beinsports1.png',
      'category': 'رياضية',
    },
    {
      'name': 'beIN Sports 2 HD',
      'url': 'http://10.3.0.4/Bein-Sport-2/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/beinsports2.png',
      'category': 'رياضية',
    },
    {
      'name': 'beIN Sports 3 HD',
      'url': 'http://10.3.0.4/Bein-Sport-3/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/beinsports3.png',
      'category': 'رياضية',
    },
    {
      'name': 'beIN Sports 4 HD',
      'url': 'http://10.3.0.4/Bein-Sport-4/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/beinsports4.png',
      'category': 'رياضية',
    },
    {
      'name': 'beIN Sports 5 HD',
      'url': 'http://10.3.0.4/Bein-Sport-5/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/beinsports5.png',
      'category': 'رياضية',
    },
    // Sport Premium
    {
      'name': 'SPORT 2 HD',
      'url': 'http://10.3.0.4/SPORT-2/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/sport2i.png',
      'category': 'رياضية',
    },
    {
      'name': 'SPORT 3 HD',
      'url': 'http://10.3.0.4/SPORT-3/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/sport3.png',
      'category': 'رياضية',
    },
    {
      'name': 'SPORT 4 HD',
      'url': 'http://10.3.0.4/SPORT-4/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/sport4.png',
      'category': 'رياضية',
    },
    // Al Kass
    {
      'name': 'Al Kass Two HD',
      'url': 'http://10.3.0.4/Al-Kass-Two/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/alkasssixhd.png',
      'category': 'رياضية',
    },
    // MBC Entertainment
    {
      'name': 'MBC 2 HD',
      'url': 'http://10.3.0.4/MBC-2/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbc2hd.png',
      'category': 'ترفيه',
    },
    {
      'name': 'MBC Action HD',
      'url': 'http://10.3.0.4/MBC-ACTION/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbcaction.png',
      'category': 'ترفيه',
    },
    {
      'name': 'Movies Action HD',
      'url': 'http://10.3.0.4/MOVIES-ACTION/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/action.png',
      'category': 'ترفيه',
    },
    // MBC General
    {
      'name': 'MBC 1 HD',
      'url': 'http://10.3.0.4/MBC-1/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbc1.png',
      'category': 'ترفيه',
    },
    {
      'name': 'MBC Iraq HD',
      'url': 'http://10.3.0.4/MBC-IRAQ/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbciraqhd.png',
      'category': 'ترفيه',
    },
    {
      'name': 'MBC 4 HD',
      'url': 'http://10.3.0.4/MBC-4/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbc4hd.png',
      'category': 'ترفيه',
    },
    {
      'name': 'MBC Masr HD',
      'url': 'http://10.3.0.4/MBC-MASR/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbcmasr.png',
      'category': 'ترفيه',
    },
    {
      'name': 'MBC Drama HD',
      'url': 'http://10.3.0.4/MBC-DRAMA/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/mbcdramahd.png',
      'category': 'ترفيه',
    },
    // Documentaries & News
    {
      'name': 'NatGeo AbuDhabi',
      'url': 'http://10.3.0.4/NatGeo-AbuDhabi/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/National_Geographic_logo.svg/512px-National_Geographic_logo.svg.png', // Stable HD Wikipedia backup logo
      'category': 'منوعة',
    },
    {
      'name': 'Al Sharqiya HD',
      'url': 'http://10.3.0.4/SHARQYIA-HD/tracks-v1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/alsharqiyahd.png',
      'category': 'منوعة',
    },
    {
      'name': 'Al Sharqiya News',
      'url': 'http://10.3.0.4/SHARQYIA-NEWS/tracks-v1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/alsharqiya.png',
      'category': 'منوعة',
    },
    {
      'name': 'Al Sumaria HD',
      'url': 'http://10.3.0.4/AL-SUMRYIA/tracks-a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/alsumariatv.png',
      'category': 'منوعة',
    },
    {
      'name': 'Hona Baghdad HD',
      'url': 'http://10.3.0.4/HONA-BAGHDAD/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/alsumariahdtv.png',
      'category': 'منوعة',
    },
    {
      'name': 'Al Iraqiya News HD',
      'url': 'http://10.3.0.4/AL-IRAQYIA-NEWS/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/iraqianews.png',
      'category': 'منوعة',
    },
    {
      'name': 'Al Iraqiya HD',
      'url': 'http://10.3.0.4/Al-IRAQYIA-HD/tracks-v1a1/mono.ts.m3u8?token=zCWqLhRssKyj70',
      'logo': 'assets/logos/iraqiaentertaiment.png',
      'category': 'منوعة',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovieProvider>(context, listen: false).loadMovies();
      // فحص الحلقات الجديدة بعد تأخير كافٍ حتى لا يتنافس مع تحميل الصفحة
      Future.delayed(const Duration(seconds: 15), _checkForNewEpisodes);
    });
  }

  Future<void> _checkForNewEpisodes() async {
    if (!mounted) return;
    try {
      final results = await NewEpisodeCheckerService.checkForNewEpisodes();
      if (!mounted || results.isEmpty) return;
      await NewEpisodeModal.show(context, results);
    } catch (_) {
      // نتجاهل أي خطأ لكي لا يؤثر على التطبيق
    }
  }

  Future<void> _onCategorySelected(String type) async {
    setState(() {
      _selectedCategoryType = type;
    });

    if (type == 'all' || type == 'live_tv') {
      return;
    }

    setState(() {
      _isCategoryLoading = true;
    });

    final movies = await _apiService.fetchMoviesByType(type);

    setState(() {
      _categoryMovies = movies;
      _isCategoryLoading = false;
    });
  }

  Color _getCategoryColor(String name) {
    if (name.contains('الرئيسية')) {
      return const Color(0xFFFFC107); // Amber Gold
    } else if (name.contains('البث')) {
      return const Color(0xFFFF3B30); // Vibrant iOS Red
    } else if (name.contains('أفلام')) {
      return const Color(0xFF00E5FF); // Electric Cyan
    } else if (name.contains('مسلسلات')) {
      return const Color(0xFF00FF87); // Spring Green
    } else if (name.contains('أنمي') || name.contains('كرتون')) {
      return const Color(0xFFFF2D55); // Neon Pink
    } else {
      return const Color(0xFFFFD552); // fallback
    }
  }

  Widget _buildPulsingDot() {
    return const _PulsingLiveIndicator();
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'الرئيسية':
        return Icons.home_max_rounded;
      case 'البث المباشر':
        return Icons.live_tv_rounded;
      case 'أفلام أجنبية':
        return Icons.movie_filter_rounded;
      case 'أفلام عربية':
        return Icons.movie_creation_rounded;
      case 'أفلام تركية':
        return Icons.movie_rounded;
      case 'مسلسلات أجنبية':
        return Icons.tv_rounded;
      case 'مسلسلات عربية':
        return Icons.live_tv_rounded;
      case 'مسلسلات تركية':
        return Icons.connected_tv_rounded;
      case 'أفلام أنمي':
        return Icons.animation_rounded;
      case 'مسلسلات أنمي':
        return Icons.theater_comedy_rounded;
      case 'أفلام كرتون':
        return Icons.child_care_rounded;
      case 'مسلسلات كرتون':
        return Icons.face_rounded;
      case 'بوكس أوفيس':
        return Icons.trending_up_rounded;
      default:
        return Icons.folder_open_rounded;
    }
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: Drawer(
        width: 250, // Reduced from default (304) to make it compact and elegant on TV/Large screens
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Stronger premium blur
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF13112B).withValues(alpha: 0.4), // Premium translucent dark purple
                    const Color(0xFF070514).withValues(alpha: 0.65), // Translucent dark surface
                  ],
                ),
              ),
              child: _buildNavigationPanel(context, false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationPanel(BuildContext context, bool isDesktopOrTV) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isDesktopOrTV) ...[
              // User Profile Section
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'مرحباً بك',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo'),
                      ),
                      Text(
                        'تسجيل الدخول',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: const Icon(Icons.person_rounded, color: primary, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Language Switcher Tile
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 20),
                      Text(
                        'Ar',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      Spacer(),
                      Text(
                        'اللغة',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.language_rounded, color: primary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
            ],
            // Categories List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _mainCategories.length,
                itemBuilder: (context, index) {
                  final cat = _mainCategories[index];
                  final isSelected = cat['type'] == _selectedCategoryType;
                  final categoryColor = _getCategoryColor(cat['name']!);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0), // Reduced from 8.0
                    child: Focus(
                      autofocus: isSelected,
                      onFocusChange: (hasFocus) {
                        if (hasFocus) setState(() {});
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          final key = event.logicalKey;
                          if (key == LogicalKeyboardKey.select ||
                              key == LogicalKeyboardKey.enter ||
                              key == LogicalKeyboardKey.numpadEnter ||
                              key == LogicalKeyboardKey.space) {
                            _onCategorySelected(cat['type']!);
                            if (!isDesktopOrTV) {
                              Navigator.pop(context);
                            }
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(
                        builder: (context) {
                          final hasFocus = Focus.of(context).hasFocus;
                          final isHighlighted = isSelected || hasFocus;
                          return AnimatedScale(
                            scale: hasFocus ? 1.04 : 1.0, // Subtler zoom
                            duration: const Duration(milliseconds: 100),
                            child: InkWell(
                              onTap: () {
                                _onCategorySelected(cat['type']!);
                                if (!isDesktopOrTV) {
                                  Navigator.pop(context);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  // Glassmorphic background when highlighted
                                  gradient: isHighlighted
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            categoryColor.withValues(alpha: 0.16),
                                            categoryColor.withValues(alpha: 0.04),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.015),
                                            Colors.white.withValues(alpha: 0.005),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isHighlighted
                                      ? [
                                          BoxShadow(
                                            color: categoryColor.withValues(alpha: 0.12),
                                            blurRadius: 10,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    children: [
                                      // Left chevron indicator pointing to the content, showing on highlight
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 150),
                                        opacity: isHighlighted ? 1.0 : 0.0,
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          color: categoryColor.withValues(alpha: 0.8),
                                          size: 16,
                                        ),
                                      ),
                                      
                                      // Space pushes the text and icon to the right
                                      const Spacer(),

                                      // Category Name
                                      Text(
                                        cat['name']!,
                                        style: TextStyle(
                                          color: isHighlighted ? Colors.white : onSurfaceVariant,
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      
                                      // Pulsing Live dot indicator next to "البث المباشر"
                                      if (cat['name']!.contains('البث')) ...[
                                        const SizedBox(width: 8),
                                        _buildPulsingDot(),
                                      ],

                                      const SizedBox(width: 10),

                                      // Icon on the right
                                      Icon(
                                        _getCategoryIcon(cat['name']!),
                                        color: isHighlighted ? categoryColor : onSurfaceVariant,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard for Live TV Channels
  Widget _buildLiveTVDashboard(BuildContext context, bool isDesktopOrTV) {
    // Filter channels based on selected subcategory
    final filteredChannels = _liveChannels.where((ch) {
      if (_selectedLiveSubcategory == 'all') return true;
      return ch['category'] == _selectedLiveSubcategory;
    }).toList();

    final liveSubcategories = [
      {'name': 'الكل', 'id': 'all'},
      {'name': 'رياضية', 'id': 'رياضية'},
      {'name': 'ترفيه', 'id': 'ترفيه'},
      {'name': 'منوعة', 'id': 'منوعة'},
    ];

    return Scaffold(
      backgroundColor: background,
      endDrawer: _buildMobileDrawer(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'البث المباشر للأقمار والقنوات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          centerTitle: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'مباشر الآن',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcategory Selectors (Horizontal list)
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: liveSubcategories.length,
              itemBuilder: (context, index) {
                final sub = liveSubcategories[index];
                final isSelected = sub['id'] == _selectedLiveSubcategory;
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final key = event.logicalKey;
                        if (key == LogicalKeyboardKey.select ||
                            key == LogicalKeyboardKey.enter ||
                            key == LogicalKeyboardKey.numpadEnter ||
                            key == LogicalKeyboardKey.space) {
                          setState(() {
                            _selectedLiveSubcategory = sub['id']!;
                          });
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final hasFocus = Focus.of(context).hasFocus;
                        final isHighlighted = isSelected || hasFocus;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedLiveSubcategory = sub['id']!;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primary : (hasFocus ? Colors.white.withValues(alpha: 0.15) : surfaceContainerHigh.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isHighlighted ? primary : Colors.white.withValues(alpha: 0.08),
                                width: isHighlighted ? 1.5 : 1.2,
                              ),
                              boxShadow: hasFocus ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                sub['name']!,
                                style: TextStyle(
                                  color: isSelected ? onPrimary : (hasFocus ? Colors.white : onSurface),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Channels Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // Dynamically calculate columns based on target card width of 180px (exactly like movies)
                int crossAxisCount = (width / 160).floor();
                if (crossAxisCount < 2) crossAxisCount = 2;
 
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.72, // Perfect aspect ratio for circular items with titles below
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredChannels.length,
                  itemBuilder: (context, index) {
                    final channel = filteredChannels[index];
                    
                    return Center(
                      child: _LiveChannelGridItem(
                        channel: channel,
                        onTap: () {
                          _pauseHeroVideo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                videoUrl: channel['url']!,
                                title: channel['name']!,
                                isLive: true,
                              ),
                            ),
                          ).then((_) => _resumeHeroVideo());
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNavText(String text, {bool isBold = false, Color color = Colors.white70, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter ||
                key == LogicalKeyboardKey.space) {
              if (onTap != null) {
                onTap();
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: hasFocus ? const Color(0xFF00E5FF) : color,
                    fontSize: 15,
                    fontWeight: (isBold || hasFocus) ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Cairo',
                    shadows: hasFocus ? [
                      const Shadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 8,
                      )
                    ] : null,
                  ),
                  child: Text(text),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTV = MediaQuery.of(context).size.width >= 1200;

    Widget mainContent = _selectedCategoryType == 'live_tv'
        ? _buildLiveTVDashboard(context, isDesktopOrTV)
        : Consumer<MovieProvider>(
                    builder: (context, movieProvider, child) {
                      if (movieProvider.isLoading) {
                        return const Scaffold(
                          backgroundColor: background,
                          body: Center(child: CircularProgressIndicator(color: primary)),
                        );
                      }

                      if (movieProvider.categories.isEmpty) {
                        return const Scaffold(
                          backgroundColor: background,
                          body: Center(
                            child: Text(
                              'لا توجد أفلام حالياً',
                              style: TextStyle(color: onSurface, fontSize: 18, fontFamily: 'Cairo'),
                            ),
                          ),
                        );
                      }

                      final firstCategoryMovies = movieProvider.categories.values.first;
                      if (_heroMovie == null && firstCategoryMovies.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _updateHeroMovie(firstCategoryMovies.first);
                        });
                      }
                      final heroMovie = _heroMovie ?? firstCategoryMovies.first;
                      final heroHeight = isDesktopOrTV ? MediaQuery.of(context).size.height * 0.75 : 450.0; // Responsive hero height
                      final topPadding = MediaQuery.of(context).padding.top;
                      final appBarHeight = 60.0 + topPadding;

                      return Scaffold(
                        backgroundColor: background,
                        extendBodyBehindAppBar: true,
                        endDrawer: _buildMobileDrawer(context),
                        appBar: PreferredSize(
                          preferredSize: Size.fromHeight(appBarHeight),
                          child: Container(
                            height: appBarHeight,
                            color: const Color(0xFF141414).withValues(alpha: 0.95), // Dark background for the app bar
                            padding: EdgeInsets.only(top: topPadding + 6, left: 24.0, right: 24.0, bottom: 6.0),
                            child: Row(
                                  children: [
                                    // Left Side: Search, Language, Profile
                                  _AppBarIconButton(
                                    icon: Icons.search_rounded,
                                    focusNode: _searchFocusNode,
                                    onTap: () {
                                      _pauseHeroVideo();
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())).then((_) => _resumeHeroVideo());
                                    },
                                  ),
                                  if (isDesktopOrTV) ...[
                                    const SizedBox(width: 24),
                                    const Text('اللغة (Ar)', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Cairo')),
                                    const SizedBox(width: 24),
                                    const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Cairo')),
                                  ],
                                  const Spacer(),

                                  // Right Side: Links and Logo
                                  if (isDesktopOrTV) ...[
                                    _buildNavText(
                                      'أطفال',
                                      color: Colors.cyan,
                                      onTap: () => _onCategorySelected('16'),
                                    ),
                                    _buildNavText(
                                      'مباشر',
                                      color: _selectedCategoryType == 'live_tv' ? const Color(0xFF00E5FF) : Colors.white70,
                                      isBold: _selectedCategoryType == 'live_tv',
                                      onTap: () => _onCategorySelected('live_tv'),
                                    ),
                                    _buildNavText(
                                      'تصفح',
                                      onTap: () => _onCategorySelected('10'),
                                    ),
                                    _buildNavText(
                                      'رياضة',
                                      onTap: () => _onCategorySelected('live_tv'),
                                    ),
                                    _buildNavText(
                                      'أفلام',
                                      color: _selectedCategoryType == '0' ? const Color(0xFF00E5FF) : Colors.white70,
                                      isBold: _selectedCategoryType == '0',
                                      onTap: () => _onCategorySelected('0'),
                                    ),
                                    _buildNavText(
                                      'مسلسلات',
                                      color: _selectedCategoryType == '1' ? const Color(0xFF00E5FF) : Colors.white70,
                                      isBold: _selectedCategoryType == '1',
                                      onTap: () => _onCategorySelected('1'),
                                    ),
                                    _buildNavText(
                                      'مجاناً',
                                      onTap: () => _onCategorySelected('all'),
                                    ),
                                    _buildNavText(
                                      'الرئيسية',
                                      color: _selectedCategoryType == 'all' ? const Color(0xFF00E5FF) : Colors.white70,
                                      isBold: _selectedCategoryType == 'all',
                                      onTap: () => _onCategorySelected('all'),
                                    ),
                                    const SizedBox(width: 24),
                                  ],
                                  // Logo
                                  const TvPlusLiveLogo(size: 44),
                                  const SizedBox(width: 16),
                                  Builder(
                                    builder: (ctx) => IconButton(
                                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                        body: Stack(
                          children: [
                            // 1. FIXED BACKGROUND BACKDROP (Never scrolls!)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: heroHeight,
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: heroMovie.posterUrl,
                                    height: heroHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                  if (_heroVideoController != null && _heroVideoController!.value.isInitialized)
                                    SizedBox(
                                      height: heroHeight,
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        child: SizedBox(
                                          width: _heroVideoController!.value.size.width,
                                          height: _heroVideoController!.value.size.height,
                                          child: VideoPlayer(_heroVideoController!),
                                        ),
                                      ),
                                    ),
                                  Container(
                                    height: heroHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          background,
                                          background.withValues(alpha: 0.4),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: heroHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          background.withValues(alpha: 0.95),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.centerLeft, // Left gradient overlay for readability
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. SCROLLABLE FOREGROUND CONTENT
                            Positioned.fill(
                              child: SingleChildScrollView(
                                controller: _mainScrollController,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 180), // Perfect top offset matching Apple TV details display
                                    Padding(
                                      padding: EdgeInsets.only(left: isDesktopOrTV ? 60.0 : 20.0, right: 20.0, bottom: 20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: primary.withValues(alpha: 0.2),
                                                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text('أصلي TVplus', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                              ),
                                              const SizedBox(width: 12),
                                              Text('2024 • أكشن • 2 ساعة 15 دقيقة', style: TextStyle(color: onSurfaceVariant, fontSize: 13, fontFamily: 'Cairo')),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            heroMovie.title,
                                            style: const TextStyle(
                                              color: onSurface,
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -1.0,
                                              shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            heroMovie.overview ?? 'رحلة ملحمية لاستعادة العرش المفقود. انضم إلى الأبطال في مغامرة تتحدى الخيال.',
                                            style: const TextStyle(color: onSurfaceVariant, fontSize: 14, height: 1.5, fontFamily: 'Cairo'),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              // زر شاهد الآن - مع دعم كامل لريمونت TV + intercept UP to go to AppBar
                                              Focus(
                                                onKeyEvent: (node, event) {
                                                  if (event is KeyDownEvent &&
                                                      event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                                    _focusSearchBar();
                                                    return KeyEventResult.handled;
                                                  }
                                                  return KeyEventResult.ignored;
                                                },
                                                child: _TvFocusButton(
                                                  isPrimary: true,
                                                  icon: Icons.play_arrow_rounded,
                                                  label: 'شاهد الآن',
                                                  onPressed: () {
                                                    _pauseHeroVideo();
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => DetailsScreen(movie: heroMovie)),
                                                    ).then((_) => _resumeHeroVideo());
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // زر التفاصيل - مع دعم كامل لريمونت TV
                                              _TvFocusButton(
                                                isPrimary: false,
                                                icon: Icons.info_outline_rounded,
                                                label: 'المزيد من التفاصيل',
                                                onPressed: () {
                                                  _pauseHeroVideo();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => DetailsScreen(movie: heroMovie)),
                                                  ).then((_) => _resumeHeroVideo());
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Conditional Content Rendering
                                    if (_selectedCategoryType == 'all') ...[
                                      // 1. Live TV Channels Row (قنوات البث المباشر)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(40.0, 24.0, 40.0, 12.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'قنوات البث المباشر',
                                                  style: TextStyle(
                                                    color: onSurface,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _onCategorySelected('live_tv'),
                                                  child: const Text(
                                                    'عرض الكل',
                                                    style: TextStyle(
                                                      color: primary,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 220,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              padding: const EdgeInsets.symmetric(horizontal: 32),
                                              itemCount: _liveChannels.length,
                                              itemBuilder: (context, index) {
                                                final channel = _liveChannels[index];
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                  child: _LiveChannelGridItem(
                                                    channel: channel,
                                                    onTap: () {
                                                      _pauseHeroVideo();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => PlayerScreen(
                                                            videoUrl: channel['url']!,
                                                            title: channel['name']!,
                                                            isLive: true,
                                                          ),
                                                        ),
                                                      ).then((_) => _resumeHeroVideo());
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      ),

                                      // Dynamic Categories Lists (All homepage sections from Vodu)
                                      ...movieProvider.categories.entries.map((entry) {
                                        final categoryTitle = entry.key;
                                        final categoryMovies = entry.value;

                                        // Match header with navigation tab to allow dynamic "View All"
                                        String typeId = 'all';
                                        for (var cat in _mainCategories) {
                                          if (cat['name'] == categoryTitle) {
                                            typeId = cat['type']!;
                                            break;
                                          }
                                        }

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(isDesktopOrTV ? 40.0 : 20.0, 24.0, isDesktopOrTV ? 40.0 : 20.0, 12.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    categoryTitle,
                                                    style: TextStyle(
                                                      color: onSurface,
                                                      fontSize: isDesktopOrTV ? 28.0 : 20.0,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                  if (typeId != 'all')
                                                    TextButton(
                                                      onPressed: () => _onCategorySelected(typeId),
                                                      child: const Text(
                                                        'عرض الكل',
                                                        style: TextStyle(
                                                          color: primary,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Cairo',
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktopOrTV ? 320.0 : 200.0,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                padding: EdgeInsets.symmetric(horizontal: isDesktopOrTV ? 32.0 : 20.0),
                                                itemCount: categoryMovies.length,
                                                itemBuilder: (context, index) {
                                                  final movie = categoryMovies[index];
                                                  return MovieCard(
                                                    movie: movie,
                                                    onFocus: (hasFocus) {
                                                      if (hasFocus) {
                                                        _updateHeroMovie(movie);
                                                      }
                                                    },
                                                    onTap: () {
                                                      _pauseHeroVideo();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => DetailsScreen(movie: movie),
                                                        ),
                                                      ).then((_) => _resumeHeroVideo());
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(height: isDesktopOrTV ? 32.0 : 16.0),
                                          ],
                                        );
                                      }).toList(),
                                    ] else ...[
                                      // Section-Specific content (e.g. Movies / Series Grid)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
                                              onPressed: () => _onCategorySelected('all'),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _mainCategories.firstWhere((c) => c['type'] == _selectedCategoryType)['name']!,
                                              style: const TextStyle(
                                                color: primary,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isCategoryLoading)
                                        const SizedBox(
                                          height: 300,
                                          child: Center(
                                            child: CircularProgressIndicator(color: primary),
                                          ),
                                        )
                                      else if (_categoryMovies.isEmpty)
                                        const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Text(
                                              'لا يوجد محتوى في هذا القسم حالياً',
                                              style: TextStyle(color: onSurfaceVariant, fontSize: 16, fontFamily: 'Cairo'),
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final width = constraints.maxWidth;
                                              // Dynamically calculate columns based on card width
                                              final targetWidth = isDesktopOrTV ? 280 : 180;
                                              int crossAxisCount = (width / targetWidth).floor();
                                              if (crossAxisCount < 2) crossAxisCount = 2;
                                              final childAspectRatio = isDesktopOrTV ? 1.25 : 1.15;

                                              return GridView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  childAspectRatio: childAspectRatio, // Precise ratio to prevent vertical overflow/squashing
                                                  crossAxisSpacing: 12,
                                                  mainAxisSpacing: 12,
                                                ),
                                                itemCount: _categoryMovies.length,
                                                itemBuilder: (context, index) {
                                                  final movie = _categoryMovies[index];
                                                  return Center(
                                                    child: MovieCard(
                                                      movie: movie,
                                                      onFocus: (hasFocus) {
                                                        if (hasFocus) {
                                                          _updateHeroMovie(movie);
                                                        }
                                                      },
                                                      onTap: () {
                                                        _pauseHeroVideo();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => DetailsScreen(movie: movie),
                                                          ),
                                                        ).then((_) => _resumeHeroVideo());
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                    const SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

    return mainContent;
  }

}

// ==========================================
// TV-FRIENDLY FOCUS BUTTON (يدعم ريمونت TV بالكامل)
// ==========================================
class _TvFocusButton extends StatefulWidget {
  final bool isPrimary;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _TvFocusButton({
    Key? key,
    required this.isPrimary,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  __TvFocusButtonState createState() => __TvFocusButtonState();
}

class __TvFocusButtonState extends State<_TvFocusButton> {
  bool _isFocused = false;

  static const Color primary = Color(0xFF00E5FF);
  static const Color onPrimary = Color(0xFF00373F);
  static const Color onSurface = Color(0xFFF0EFFF);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? (_isFocused ? primary.withValues(alpha: 0.9) : primary)
                  : (_isFocused
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.10)),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: _isFocused
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.2),
                width: _isFocused ? 2.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: widget.isPrimary
                            ? primary.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 24,
                  color: widget.isPrimary ? onPrimary : onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: widget.isPrimary ? onPrimary : onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingLiveIndicator extends StatefulWidget {
  const _PulsingLiveIndicator({Key? key}) : super(key: key);

  @override
  __PulsingLiveIndicatorState createState() => __PulsingLiveIndicatorState();
}

class __PulsingLiveIndicatorState extends State<_PulsingLiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFFF3B30),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF3B30),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }
}

class _LiveChannelGridItem extends StatefulWidget {
  final Map<String, String> channel;
  final VoidCallback onTap;

  const _LiveChannelGridItem({
    Key? key,
    required this.channel,
    required this.onTap,
  }) : super(key: key);

  @override
  __LiveChannelGridItemState createState() => __LiveChannelGridItemState();
}

class __LiveChannelGridItemState extends State<_LiveChannelGridItem> {
  bool _isFocused = false;
  bool _isHovered = false;

  bool get _isHighlighted => _isFocused || _isHovered;

  // Design tokens matching MovieCard
  static const Color primaryColor = Color(0xFFFFD552);
  static const Color onSurfaceColor = Color(0xFFE5E2E1);
  static const Color onSurfaceVarColor = Color(0xFFD1C5AC);

  Widget _buildFallbackLogo(String channelName) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          channelName.split(' ').take(2).join('\n'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildChannelLogo(String logoPath, String channelName) {
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: logoPath,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
        },
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildFallbackLogo(channelName),
      );
    } else {
      return Image.asset(
        logoPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo(channelName);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.enter || 
                key == LogicalKeyboardKey.select || 
                key == LogicalKeyboardKey.numpadEnter) {
              widget.onTap();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHighlighted ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Container (140x140)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: _isHighlighted
                        ? Border.all(color: primaryColor.withValues(alpha: 0.8), width: 3)
                        : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                    boxShadow: _isHighlighted
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Premium gradient background for the channel badge
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        
                        // Channel Logo (Centered inside circle, fitted beautifully)
                        Padding(
                          padding: const EdgeInsets.all(22.0),
                          child: _buildChannelLogo(widget.channel['logo']!, widget.channel['name']!),
                        ),

                        // Hover/Focus overlay with play button
                        AnimatedOpacity(
                          opacity: _isHighlighted ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),

                        // LIVE Badge (Floating top center)
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Channel Title
                SizedBox(
                  width: 140,
                  child: Text(
                    widget.channel['name']!,
                    style: TextStyle(
                      color: _isHighlighted ? primaryColor : onSurfaceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Subcategory Subtitle
                SizedBox(
                  width: 140,
                  child: Text(
                    widget.channel['category'] ?? 'قناة بث مباشر',
                    style: const TextStyle(
                      color: onSurfaceVarColor,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  const _AppBarIconButton({Key? key, required this.icon, required this.onTap, this.focusNode}) : super(key: key);

  @override
  __AppBarIconButtonState createState() => __AppBarIconButtonState();
}

class __AppBarIconButtonState extends State<_AppBarIconButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (focused) => setState(() => _hasFocus = focused),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter ||
                key == LogicalKeyboardKey.space) {
              widget.onTap();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hasFocus ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _hasFocus ? const Color(0xFF00E5FF) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _hasFocus ? const Color(0xFF00E5FF) : Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

