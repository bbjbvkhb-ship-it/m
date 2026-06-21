
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/netflix_theme.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import 'netflix_player_screen.dart';
import 'search_screen.dart';
import '../providers/movie_provider.dart';
import 'package:provider/provider.dart';

/// شاشة التفاصيل بتصميم Netflix
class NetflixDetailsScreen extends StatefulWidget {
  final Movie movie;

  const NetflixDetailsScreen({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  _NetflixDetailsScreenState createState() => _NetflixDetailsScreenState();
}

class _NetflixDetailsScreenState extends State<NetflixDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _playButtonFocusNode = FocusNode();
  final FocusNode _infoButtonFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  Movie? _detailedMovie;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDetails();

    // طلب التركيز التلقائي على زر التشغيل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _playButtonFocusNode.canRequestFocus) {
        _playButtonFocusNode.requestFocus();
      }
    });
  }

  Future<void> _loadDetails() async {
    try {
      final m = await _apiService.fetchMovieDetails(
          widget.movie.id, widget.movie.title, widget.movie.posterUrl);
      if (mounted) {
        setState(() {
          _detailedMovie = m;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading details in NetflixDetailsScreen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _playButtonFocusNode.dispose();
    _infoButtonFocusNode.dispose();
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 700;
    final showTopBar = _scrollController.hasClients && 
                      _scrollController.offset > 200;

    return Scaffold(
      backgroundColor: NetflixTheme.netflixBlack,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // شريط علوي متحرك
          SliverAppBar(
            backgroundColor: showTopBar 
                ? NetflixTheme.netflixBlack 
                : Colors.transparent,
            elevation: 0,
            expandedHeight: isTV ? 600 : 500,
            floating: false,
            pinned: true,
            leading: _buildBackButton(isTV),
            actions: [
              _buildTopBarActions(isTV),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroSection(isTV),
            ),
          ),

          // معلومات الفيلم
          SliverToBoxAdapter(
            child: _buildMovieInfo(isTV),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(bool isTV) {
    return Focus(
      focusNode: _backButtonFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: hasFocus 
                  ? NetflixTheme.netflixRed 
                  : NetflixTheme.netflixWhite,
            ),
            onPressed: () => Navigator.pop(context),
            iconSize: isTV ? 32 : 24,
          );
        },
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
                        Navigator.pop(context); // Go back home
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
            color: hasFocus 
                ? NetflixTheme.netflixRed 
                : NetflixTheme.netflixWhite,
            onPressed: onPressed,
            iconSize: isTV ? 32 : 24,
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(bool isTV) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // صورة الخلفية
        Image.network(
          widget.movie.posterUrl,
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
      ],
    );
  }

  Widget _buildMovieInfo(bool isTV) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTV ? 80 : 20,
        vertical: isTV ? 40 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الفيلم
          Text(
            widget.movie.title,
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

          // معلومات الفيلم
          Wrap(
            spacing: 16,
            children: [
              if (widget.movie.year != null)
                Text(
                  widget.movie.year!,
                  style: TextStyle(
                    color: NetflixTheme.netflixLightGray,
                    fontSize: isTV ? 16 : 14,
                    fontFamily: 'NetflixSans',
                  ),
                ),
              if (widget.movie.rating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: NetflixTheme.netflixRed,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.movie.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        color: NetflixTheme.netflixLightGray,
                        fontSize: isTV ? 16 : 14,
                        fontFamily: 'NetflixSans',
                      ),
                    ),
                  ],
                ),
              if (widget.movie.genres != null && widget.movie.genres!.isNotEmpty)
                Text(
                  widget.movie.genres!.join(' • '),
                  style: TextStyle(
                    color: NetflixTheme.netflixLightGray,
                    fontSize: isTV ? 16 : 14,
                    fontFamily: 'NetflixSans',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // أزرار التشغيل
          Row(
            children: [
              _buildMainButton(
                focusNode: _playButtonFocusNode,
                icon: Icons.play_arrow,
                label: 'تشغيل',
                isTV: isTV,
                isPrimary: true,
                onPressed: () {
                  final activeMovie = _detailedMovie ?? widget.movie;
                  if (activeMovie.episodes != null && activeMovie.episodes!.isNotEmpty) {
                    final firstEp = activeMovie.episodes!.first;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NetflixPlayerScreen(
                        videoUrl: firstEp.videoUrl,
                        title: '${activeMovie.title} - ${firstEp.title}',
                        subtitleUrl: firstEp.subtitleUrl,
                      ),
                    ));
                    return;
                  }
                  if (activeMovie.videoUrl != null && activeMovie.videoUrl!.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NetflixPlayerScreen(
                        videoUrl: activeMovie.videoUrl!,
                        title: activeMovie.title,
                        subtitleUrl: activeMovie.subtitleUrl,
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
              _buildMainButton(
                focusNode: _infoButtonFocusNode,
                icon: Icons.info_outline,
                label: 'معلومات',
                isTV: isTV,
                onPressed: () {
                  final activeMovie = _detailedMovie ?? widget.movie;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: NetflixTheme.netflixDark,
                      title: Text(activeMovie.title, style: const TextStyle(color: NetflixTheme.netflixWhite, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeMovie.director != null && activeMovie.director!.isNotEmpty) ...[
                            Text('المخرج: ${activeMovie.director}', style: const TextStyle(color: NetflixTheme.netflixLightGray, fontFamily: 'Cairo')),
                            const SizedBox(height: 8),
                          ],
                          if (activeMovie.writers != null && activeMovie.writers!.isNotEmpty) ...[
                            Text('المؤلف: ${activeMovie.writers}', style: const TextStyle(color: NetflixTheme.netflixLightGray, fontFamily: 'Cairo')),
                            const SizedBox(height: 8),
                          ],
                          Text('التقييم: ${activeMovie.rating?.toStringAsFixed(1) ?? '0.0'}', style: const TextStyle(color: NetflixTheme.netflixLightGray, fontFamily: 'Cairo')),
                          const SizedBox(height: 8),
                          Text('سنة الإنتاج: ${activeMovie.year ?? 'غير معروف'}', style: const TextStyle(color: NetflixTheme.netflixLightGray, fontFamily: 'Cairo')),
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
          ),

          const SizedBox(height: 32),

          // وصف الفيلم
          Text(
            widget.movie.overview ?? '',
            style: TextStyle(
              color: NetflixTheme.netflixLightGray,
              fontSize: isTV ? 18 : 16,
              fontFamily: 'NetflixSans',
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // طاقم العمل
          if (widget.movie.cast != null && widget.movie.cast!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طاقم العمل',
                  style: TextStyle(
                    color: NetflixTheme.netflixWhite,
                    fontSize: isTV ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NetflixSans',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: widget.movie.cast!.map((actor) {
                    return _buildCastChip(actor, isTV);
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required FocusNode focusNode,
    required IconData icon,
    required String label,
    required bool isTV,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Focus(
      focusNode: focusNode,
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
                color: isPrimary
                    ? (hasFocus 
                        ? NetflixTheme.netflixWhite 
                        : NetflixTheme.netflixRed)
                    : (hasFocus 
                        ? NetflixTheme.netflixDark.withOpacity(0.8)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(4),
                border: !isPrimary
                    ? Border.all(
                        color: hasFocus 
                            ? NetflixTheme.netflixWhite 
                            : NetflixTheme.netflixLightGray,
                        width: 2,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isPrimary
                        ? (hasFocus 
                            ? NetflixTheme.netflixBlack 
                            : NetflixTheme.netflixWhite)
                        : (hasFocus 
                            ? NetflixTheme.netflixWhite 
                            : NetflixTheme.netflixLightGray),
                    size: isTV ? 28 : 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isPrimary
                          ? (hasFocus 
                              ? NetflixTheme.netflixBlack 
                              : NetflixTheme.netflixWhite)
                          : (hasFocus 
                              ? NetflixTheme.netflixWhite 
                              : NetflixTheme.netflixLightGray),
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

  Widget _buildCastChip(String actor, bool isTV) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTV ? 16 : 12,
        vertical: isTV ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: NetflixTheme.netflixDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: NetflixTheme.netflixGray,
          width: 1,
        ),
      ),
      child: Text(
        actor,
        style: TextStyle(
          color: NetflixTheme.netflixLightGray,
          fontSize: isTV ? 14 : 12,
          fontFamily: 'NetflixSans',
        ),
      ),
    );
  }
}
