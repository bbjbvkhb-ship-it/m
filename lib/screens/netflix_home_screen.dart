
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/netflix_theme.dart';
import '../widgets/netflix_movie_row.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../services/api_service.dart';
import 'search_screen.dart';
import 'netflix_details_screen.dart';
import 'netflix_player_screen.dart';
import 'package:provider/provider.dart';

/// الشاشة الرئيسية بتصميم Netflix
class NetflixHomeScreen extends StatefulWidget {
  const NetflixHomeScreen({Key? key}) : super(key: key);

  @override
  _NetflixHomeScreenState createState() => _NetflixHomeScreenState();
}

class _NetflixHomeScreenState extends State<NetflixHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _heroFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  Movie? _featuredMovieDetailed;

  // قائمة الفئات مثل Netflix
  final List<String> _categories = [
    'الأكثر مشاهدة',
    'أفلام أكشن',
    'أفلام دراما',
    'أفلام كوميديا',
    'أفلام رعب',
    'مسلسلات دراما',
    'مسلسلات كوميديا',
    'أنمي',
    'وثائقيات',
    'أفلام عربية',
    'مسلسلات عربية',
    'أفلام تركية',
    'مسلسلات تركية',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _heroFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedMovieDetails(Movie movie) async {
    if (_featuredMovieDetailed?.id == movie.id) return;
    try {
      final detailed = await _apiService.fetchMovieDetails(movie.id, movie.title, movie.posterUrl);
      if (mounted) {
        setState(() {
          _featuredMovieDetailed = detailed;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured movie details: $e');
    }
  }

  void _onScroll() {
    // تحديث حالة شريط التنقل عند التمرير
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 700;
    final movies = Provider.of<MovieProvider>(context).movies;

    if (movies.isNotEmpty && _featuredMovieDetailed == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFeaturedMovieDetails(movies.first);
      });
    }

    return Scaffold(
      backgroundColor: NetflixTheme.netflixBlack,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // شريط Netflix العلوي
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: isTV ? 500 : 400,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: _buildNetflixLogo(),
              background: _buildHeroSection(movies, isTV),
            ),
            actions: [
              _buildTopBarActions(isTV),
            ],
          ),

          // صفوف الأفلام
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return NetflixMovieRow(
                  title: _categories[index],
                  movies: movies,
                  isTV: isTV,
                );
              },
              childCount: _categories.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetflixLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: const Text(
        'NETFLIX',
        style: TextStyle(
          color: NetflixTheme.netflixRed,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontFamily: 'NetflixSans',
        ),
      ),
    );
  }

  Widget _buildTopBarActions(bool isTV) {
    return Row(
      children: [
        _buildTopBarButton(
          icon: Icons.search,
          label: 'بحث',
          isTV: isTV,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
          },
        ),
        _buildTopBarButton(
          icon: Icons.notifications,
          label: 'إشعارات',
          isTV: isTV,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: NetflixTheme.netflixDark,
                title: const Text('الإشعارات', style: TextStyle(color: NetflixTheme.netflixWhite, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                content: const Text('لا توجد إشعارات جديدة حالياً.', style: TextStyle(color: NetflixTheme.netflixLightGray, fontFamily: 'Cairo')),
                actions: [
                  TextButton(
                    child: const Text('إغلاق', style: TextStyle(color: NetflixTheme.netflixRed, fontFamily: 'Cairo')),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
        _buildTopBarButton(
          icon: Icons.account_circle,
          label: 'حسابي',
          isTV: isTV,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: NetflixTheme.netflixDark,
                title: const Text('الحساب والإعدادات', style: TextStyle(color: NetflixTheme.netflixWhite, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مرحباً بك في TV Plus!', style: TextStyle(color: NetflixTheme.netflixWhite, fontFamily: 'Cairo')),
                    const SizedBox(height: 16),
                    const Text('المظهر الحالي: Netflix', style: TextStyle(color: NetflixTheme.netflixLightGray, fontFamily: 'Cairo')),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: const Color(0xFF00373F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('التبديل إلى مظهر TV Plus', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<MovieProvider>(context, listen: false).setTheme('tv_plus');
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('إغلاق', style: TextStyle(color: NetflixTheme.netflixRed, fontFamily: 'Cairo')),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required String label,
    required bool isTV,
    required VoidCallback onPressed,
  }) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.numpadEnter) {
            onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return IconButton(
            icon: Icon(icon),
            color: hasFocus ? NetflixTheme.netflixRed : NetflixTheme.netflixWhite,
            onPressed: onPressed,
            iconSize: isTV ? 32 : 24,
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(List<Movie> movies, bool isTV) {
    if (movies.isEmpty) {
      return Container(
        color: NetflixTheme.netflixDark,
        child: const Center(
          child: CircularProgressIndicator(
            color: NetflixTheme.netflixRed,
          ),
        ),
      );
    }

    final featuredMovie = movies.first;
    return Stack(
      fit: StackFit.expand,
      children: [
        // صورة الخلفية
        Image.network(
          featuredMovie.posterUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: NetflixTheme.netflixDark,
            );
          },
        ),

        // تدرج لوني
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
                NetflixTheme.netflixBlack,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // معلومات الفيلم
        Positioned(
          bottom: isTV ? 100 : 80,
          left: isTV ? 80 : 20,
          right: isTV ? 80 : 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الفيلم
              Text(
                featuredMovie.title,
                style: TextStyle(
                  color: NetflixTheme.netflixWhite,
                  fontSize: isTV ? 48 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NetflixSans',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // وصف الفيلم
              Text(
                featuredMovie.overview ?? '',
                style: TextStyle(
                  color: NetflixTheme.netflixLightGray,
                  fontSize: isTV ? 18 : 14,
                  fontFamily: 'NetflixSans',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 24),

              // أزرار التشغيل
              Row(
                children: [
                  _buildHeroButton(
                    icon: Icons.play_arrow,
                    label: 'تشغيل',
                    isTV: isTV,
                    onPressed: () {
                      final movieToPlay = _featuredMovieDetailed ?? featuredMovie;
                      if (movieToPlay.videoUrl != null && movieToPlay.videoUrl!.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => NetflixPlayerScreen(
                            videoUrl: movieToPlay.videoUrl!,
                            title: movieToPlay.title,
                          ),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('رابط البث غير متوفر حالياً', style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Colors.redAccent,
                        ));
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildHeroButton(
                    icon: Icons.info_outline,
                    label: 'معلومات',
                    isTV: isTV,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => NetflixDetailsScreen(movie: _featuredMovieDetailed ?? featuredMovie),
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroButton({
    required IconData icon,
    required String label,
    required bool isTV,
    required VoidCallback onPressed,
  }) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.numpadEnter) {
            onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isTV ? 32 : 24,
                vertical: isTV ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: hasFocus 
                    ? NetflixTheme.netflixWhite 
                    : NetflixTheme.netflixDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: hasFocus 
                        ? NetflixTheme.netflixBlack 
                        : NetflixTheme.netflixWhite,
                    size: isTV ? 28 : 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: hasFocus 
                          ? NetflixTheme.netflixBlack 
                          : NetflixTheme.netflixWhite,
                      fontSize: isTV ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NetflixSans',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
