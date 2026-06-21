import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/tmdb_service.dart';
import 'player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/watchlist_service.dart';


class DetailsScreen extends StatefulWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final ApiService _apiService = ApiService();
  Movie? _detailedMovie;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  // Season selection
  int _selectedSeasonIndex = -1; // -1 = الموسم الحالي
  List<Episode>? _displayedEpisodes; // الحلقات المعروضة (يتغير عند تغيير الموسم)
  bool _isSeasonLoading = false;
  final Map<String, List<Episode>> _seasonEpisodesCache = {};

  // Trailer player
  VideoPlayerController? _trailerController;
  ChewieController? _chewieController;

  static const Color background   = Color(0xFF141414);
  static const Color primary      = Color(0xFF00E5FF);
  static const Color onPrimary    = Color(0xFF00373F);
  static const Color onSurface    = Color(0xFFF0EFFF);
  static const Color onSurfaceVar = Color(0xFFA59EC6);
  static const Color outlineVar   = Color(0xFF2E265C);

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadFollowState();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _trailerController?.dispose();
    super.dispose();
  }

  Future<void> _initTrailer(String url) async {
    if (_trailerController != null) return;
    try {
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
          'Referer': 'https://movie.vodu.me/',
        },
      );
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() {
        _trailerController = ctrl;
        _chewieController = ChewieController(
          videoPlayerController: ctrl,
          autoPlay: false,       // لا يشغل تلقائياً
          looping: false,
          allowFullScreen: false, // يمنع التوسع للشاشة الكاملة
          fullScreenByDefault: false,
          allowMuting: true,
          showControls: true,
          aspectRatio: 16 / 9,   // نسبة عرض ثابتة 16:9
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF00E5FF),
            handleColor: const Color(0xFF00E5FF),
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
        );
      });
    } catch (e) {
      debugPrint('Trailer init error: $e');
    }
  }

  Future<void> _loadFollowState() async {
    final following = await WatchlistService.isFollowing(widget.movie.id);
    if (mounted) setState(() => _isFollowing = following);
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);
    final movie = _detailedMovie ?? widget.movie;
    if (_isFollowing) {
      await WatchlistService.removeFromWatchlist(movie.id);
      if (mounted) {
        setState(() { _isFollowing = false; _isFollowLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تمت إزالة المسلسل من قائمة المتابعة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      final episodeCount = movie.episodes?.length ?? 0;
      final added = await WatchlistService.addToWatchlist(WatchedSeries(
        id: movie.id,
        title: movie.title,
        posterUrl: movie.posterUrl,
        episodeCount: episodeCount,
      ));
      if (mounted) {
        setState(() { _isFollowLoading = false; });
        if (added) {
          setState(() => _isFollowing = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ تمت إضافة المسلسل للمتابعة! ستُنبَّه عند نزول حلقات جديدة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Color(0xFF00373F),
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('⚠️ لا يمكن إضافة أكثر من 5 مسلسلات للمتابعة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  Future<void> _loadDetails() async {
    final m = await _apiService.fetchMovieDetails(
      widget.movie.id, widget.movie.title, widget.movie.posterUrl);
    if (mounted) {
      int currentSeasonIdx = 0;
      if (m.seasons != null && m.seasons!.isNotEmpty) {
        final matchIdx = m.seasons!.indexWhere((s) => s.id == m.id || s.id == '${m.id}-season-${m.seasonNumber}');
        if (matchIdx != -1) {
          currentSeasonIdx = matchIdx;
        } else if (m.seasonNumber != null) {
          final numIdx = m.seasons!.indexWhere((s) => s.seasonNumber == m.seasonNumber);
          if (numIdx != -1) {
            currentSeasonIdx = numIdx;
          }
        }
      }
      if (m.episodes != null) {
        _seasonEpisodesCache[m.id] = m.episodes!;
      }
      if (m.seasons != null && m.seasons!.isNotEmpty && currentSeasonIdx >= 0 && currentSeasonIdx < m.seasons!.length) {
        final currentSeasonMovie = m.seasons![currentSeasonIdx];
        if (m.episodes != null) {
          _seasonEpisodesCache[currentSeasonMovie.id] = m.episodes!;
        }
      }
      setState(() {
        _detailedMovie = m;
        _isLoading = false;
        _displayedEpisodes = m.episodes;
        _selectedSeasonIndex = m.seasons != null && m.seasons!.isNotEmpty ? currentSeasonIdx : -1;
      });
      // 1️⃣ أولاً: جرّب تريلر YouTube عبر TMDB (بدون إعلانات)
      final ytKey = await TmdbService.getYoutubeTrailerKey(
        m.title, year: m.year);
      if (ytKey != null && mounted) {
        await _initYoutubeTrailer(ytKey);
      }
      // 2️⃣ احتياطي: رابط -t.mp4 من الموقع إذا لم يُوجد تريلر YouTube
      if (_trailerController == null &&
          m.trailerUrl != null &&
          m.trailerUrl!.isNotEmpty &&
          mounted) {
        _initTrailer(m.trailerUrl!);
      }
    }
  }

  /// تبديل الموسم — يجلب حلقات الموسم الجديد مباشرةً في نفس الشاشة
  Future<void> _switchSeason(int seasonIndex, Movie seasonMovie) async {
    if (_selectedSeasonIndex == seasonIndex) return;

    final cached = _seasonEpisodesCache[seasonMovie.id];
    if (cached != null) {
      setState(() {
        _selectedSeasonIndex = seasonIndex;
        _displayedEpisodes = cached;
        _isSeasonLoading = false;
      });
      return;
    }

    if (seasonMovie.episodes != null && seasonMovie.episodes!.isNotEmpty) {
      setState(() {
        _selectedSeasonIndex = seasonIndex;
        _displayedEpisodes = seasonMovie.episodes;
        _isSeasonLoading = false;
      });
      return;
    }

    setState(() {
      _selectedSeasonIndex = seasonIndex;
      _isSeasonLoading = true;
      _displayedEpisodes = null;
    });
    try {
      final details = await _apiService.fetchMovieDetails(
        seasonMovie.id, seasonMovie.title, seasonMovie.posterUrl);
      if (mounted) {
        if (details.episodes != null) {
          _seasonEpisodesCache[seasonMovie.id] = details.episodes!;
        }
        setState(() {
          _displayedEpisodes = details.episodes ?? [];
          _isSeasonLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSeasonLoading = false);
    }
  }

  /// يستخرج رابط الفيديو المباشر من YouTube (بدون إعلانات) باستخدام
  /// youtube_explode_dart ثم يُشغّله بـ video_player العادي.
  Future<void> _initYoutubeTrailer(String youtubeKey) async {
    if (_trailerController != null) return;
    final yt = YoutubeExplode();
    try {
      final manifest =
          await yt.videos.streamsClient.getManifest(youtubeKey);
      // اختر أفضل مقاطع الفيديو + الصوت المدمج (muxed) بجودة معقولة
      final streams = manifest.muxed.sortByVideoQuality();
      if (streams.isEmpty) return;
      // فضّل 720p أو أقل لتجنّب بطء التحميل على التلفاز
      final stream = streams.firstWhere(
        (s) => s.videoQuality == VideoQuality.high720 ||
               s.videoQuality == VideoQuality.medium480 ||
               s.videoQuality == VideoQuality.medium360,
        orElse: () => streams.last,
      );
      final url = stream.url.toString();
      if (!mounted) return;
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() {
        _trailerController = ctrl;
        _chewieController = ChewieController(
          videoPlayerController: ctrl,
          autoPlay: false,
          looping: false,
          allowFullScreen: false,
          fullScreenByDefault: false,
          allowMuting: true,
          showControls: true,
          aspectRatio: 16 / 9,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF00E5FF),
            handleColor: const Color(0xFF00E5FF),
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
        );
      });
    } catch (e) {
      debugPrint('YouTube trailer init error: $e');
    } finally {
      yt.close();
    }
  }

  String _formatEpisodeTitle(Episode episode, int episodeIndex) {
    final rawTitle = episode.title;
    final cleanRaw = rawTitle.trim();
    final String prefix = 'الحلقة $episodeIndex';
    if (cleanRaw.isEmpty) return prefix;
    if (RegExp(r'^\d+$').hasMatch(cleanRaw)) {
      final intNumber = int.tryParse(cleanRaw) ?? episodeIndex;
      return 'الحلقة $intNumber';
    }
    final genericMatch = RegExp(r'^(episode|ep|ep\.|الحلقة|حلقة)\s*(\d+)$', caseSensitive: false).firstMatch(cleanRaw);
    if (genericMatch != null) {
      final intNumber = int.tryParse(genericMatch.group(2)!) ?? episodeIndex;
      return 'الحلقة $intNumber';
    }
    String extraTitle = cleanRaw;
    final pattern = RegExp(r'^(episode|ep|ep\.|الحلقة|حلقة)\s*\d+\s*[-:]?\s*', caseSensitive: false);
    if (pattern.hasMatch(extraTitle)) {
      final match = pattern.firstMatch(extraTitle)!;
      extraTitle = extraTitle.substring(match.end).trim();
    }
    if (extraTitle.isEmpty) return prefix;
    return '$prefix | $extraTitle';
  }

  void _playMovie(Movie m) {
    if (m.episodes != null && m.episodes!.isNotEmpty) {
      final firstEp = m.episodes!.first;
      final formattedTitle = _formatEpisodeTitle(firstEp, 1);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(
          videoUrl: firstEp.videoUrl,
          title: formattedTitle,
          subtitleUrl: firstEp.subtitleUrl,
          qualities: firstEp.videoQualities,
          episodes: m.episodes,
          currentEpisodeIndex: 0,
        ),
      ));
      return;
    }
    if (m.videoUrl == null || m.videoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('رابط البث غير متوفر حالياً', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        videoUrl: m.videoUrl!,
        title: m.title,
        subtitleUrl: m.subtitleUrl,
        qualities: m.videoQualities,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final movie = _detailedMovie ?? widget.movie;
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTV = constraints.maxWidth > 900;
          if (isTV) {
            return _buildTvLayout(context, movie);
          } else {
            return _buildMobileLayout(context, movie);
          }
        },
      ),
    );
  }

  Widget _buildTvLayout(BuildContext context, Movie movie) {
    return Stack(
      children: [
        // خلفية ضبابية
        Positioned.fill(
          child: CachedNetworkImage(imageUrl: movie.posterUrl, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xF5070514), Color(0xCC070514), Color(0x44070514)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF141414), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.6],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(isTV: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // القسم العلوي: الهيرو والتفاصيل
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── الجانب الأيسر: المعلومات والأزرار ──
                          Expanded(
                            flex: 5,
                            child: _buildInfoSection(movie, isTV: true),
                          ),
                          const SizedBox(width: 48),
                          // ── الجانب الأيمن: البوستر أو التريلر بوزن محدد ──
                          Expanded(
                            flex: 3,
                            child: _PosterWidget(
                              posterUrl: movie.posterUrl,
                              chewieController: _chewieController,
                              onTap: () => _playMovie(movie),
                            ),
                          ),
                        ],
                      ),
                      
                      // ── قسم المواسم والحلقات (مدمجان معاً) ──
                      if (!_isLoading && (
                        (movie.seasons != null && movie.seasons!.isNotEmpty) ||
                        (_displayedEpisodes != null && _displayedEpisodes!.isNotEmpty)
                      )) ...[
                        const SizedBox(height: 40),
                        _buildSeasonsAndEpisodesSection(movie, isTV: true),
                      ],

                      // ── قسم طاقم العمل (إذا كان متوفراً) ──
                      if (!_isLoading && movie.cast != null && movie.cast!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'طاقم العمل',
                          style: TextStyle(
                            color: primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: movie.cast!.length,
                            itemBuilder: (_, i) => _buildCastChip(movie.cast![i], i == 0),
                          ),
                        ),
                      ],

                      // ── قسم المحتويات المقترحة (إذا وُجدت) ──
                      if (!_isLoading && movie.similarMovies != null && movie.similarMovies!.isNotEmpty) ...[
                        const SizedBox(height: 40),
                        _buildSuggestedSection(movie, isTV: true),
                      ],
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // تخطيط موبايل — عمودي تقليدي
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, Movie movie) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // التريلر بارتفاع ثابت 200px - لا يتمدد أبداً
              if (_chewieController != null)
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRect(
                    child: OverflowBox(
                      maxHeight: 200,
                      alignment: Alignment.center,
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                )
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: CachedNetworkImage(
                        imageUrl: movie.posterUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholder: (context, url) => Container(
                          color: Colors.white10,
                          child: const Center(
                            child: CircularProgressIndicator(color: primary),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.movie_rounded,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                        fadeInDuration: const Duration(milliseconds: 300),
                        memCacheWidth: 600,
                        memCacheHeight: 800,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [background, Colors.transparent],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                    // زر التشغيل المركزي (موبايل)
                    if (!_isLoading)
                      GestureDetector(
                        onTap: () => _playMovie(movie),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              size: 44, color: onPrimary),
                        ),
                      )
                    else
                      const CircularProgressIndicator(color: primary),
                  ],
                ),

              // المعلومات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInfoSection(movie, isTV: false),
              ),
            ],
          ),
        ),

        // شريط علوي شفاف
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopBar(isTV: false),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // قسم المعلومات المشترك (TV + موبايل)
  // ═══════════════════════════════════════════════════════
  Widget _buildInfoSection(Movie movie, {required bool isTV}) {
    final titleSize   = isTV ? 40.0 : 28.0;
    final bodySize    = isTV ? 15.0 : 14.0;
    final sectionSize = isTV ? 22.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: TextStyle(
            color: onSurface,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            letterSpacing: -1,
            height: 1.1,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // ميتاداتا
        Wrap(
          spacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 4),
                Text(movie.rating?.toStringAsFixed(1) ?? '—',
                    style: const TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            if (movie.year != null)
              Text(movie.year!, style: const TextStyle(color: onSurfaceVar, fontSize: 13)),
            if (movie.genres != null && movie.genres!.isNotEmpty)
              Text(movie.genres!.take(2).join(' • '),
                  style: const TextStyle(color: onSurfaceVar, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),

        // الوصف
        Text(
          movie.overview ?? 'جاري جلب القصة...',
          style: TextStyle(
            color: onSurfaceVar, fontSize: bodySize, height: 1.6, fontFamily: 'Cairo'),
          maxLines: isTV ? 4 : 5,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 28),

        // أزرار التشغيل
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: primary))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TvButton(
                autofocus: isTV,
                isPrimary: true,
                icon: Icons.play_arrow_rounded,
                label: 'شاهد الآن',
                onPressed: () => _playMovie(movie),
              ),
              // زر المتابعة الذكي
              if (movie.episodes != null && movie.episodes!.isNotEmpty)
                _isFollowLoading
                  ? const SizedBox(
                      width: 48, height: 48,
                      child: Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2)),
                    )
                  : _TvButton(
                      icon: _isFollowing
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      label: _isFollowing ? 'متابَع ✓' : 'تنبيه حلقات',
                      isPrimary: _isFollowing,
                      onPressed: _toggleFollow,
                    ),
              _TvButton(
                icon: Icons.thumb_up_rounded,
                label: 'تقييم',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('شكراً لتقييمك!', style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: primary,
                  ),
                ),
              ),
            ],
          ),

        // المواسم والحلقات — موبايل وTV (دالة موحدة)
        if (!isTV && !_isLoading && (
          (movie.seasons != null && movie.seasons!.isNotEmpty) ||
          (_displayedEpisodes != null && _displayedEpisodes!.isNotEmpty)
        )) ...[
          const SizedBox(height: 36),
          _buildSeasonsAndEpisodesSection(movie, isTV: false),
        ],


        // طاقم العمل
        if (!_isLoading && movie.cast != null && movie.cast!.isNotEmpty) ...[
          const SizedBox(height: 36),
          Text('طاقم العمل',
              style: TextStyle(
                  color: primary, fontSize: sectionSize,
                  fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: movie.cast!.length,
              itemBuilder: (_, i) => _buildCastChip(movie.cast![i], i == 0),
            ),
          ),
        ],

        // المحتويات المقترحة — موبايل
        if (!isTV && !_isLoading && movie.similarMovies != null && movie.similarMovies!.isNotEmpty) ...[
          const SizedBox(height: 36),
          _buildSuggestedSection(movie, isTV: false),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // قسم المواسم + الحلقات الموحّد — تصميم Glassmorphic
  // ═══════════════════════════════════════════════════════
  Widget _buildSeasonsAndEpisodesSection(Movie movie, {required bool isTV}) {
    final episodes = _displayedEpisodes ?? movie.episodes ?? [];
    final seasons  = movie.seasons ?? [];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── رأس القسم ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(Icons.video_library_rounded, color: primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الحلقات',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (seasons.isNotEmpty)
                          Text(
                            '${seasons.length} موسم',
                            style: TextStyle(
                              color: primary.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (_isSeasonLoading)
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                      )
                    else if (episodes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${episodes.length} حلقة',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── تبويبات المواسم (إذا وُجدت) ──
              if (seasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 20, left: 8),
                  child: SizedBox(
                    height: 185,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: seasons.length,
                      itemBuilder: (context, idx) {
                        final isSelected = _selectedSeasonIndex == idx;
                        final seasonMovie = seasons[idx];
                        final label = seasonMovie.title.contains('الموسم') || seasonMovie.title.contains('Season')
                            ? seasonMovie.title
                            : 'الموسم ${seasonMovie.seasonNumber ?? idx + 1}';
                        final posterUrl = seasonMovie.posterUrl.isNotEmpty
                            ? seasonMovie.posterUrl
                            : movie.posterUrl;

                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Focus(
                            onKeyEvent: (_, event) {
                              if (event is KeyDownEvent) {
                                final k = event.logicalKey;
                                if (k == LogicalKeyboardKey.select ||
                                    k == LogicalKeyboardKey.enter ||
                                    k == LogicalKeyboardKey.numpadEnter) {
                                  _switchSeason(idx, seasonMovie);
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Builder(
                              builder: (ctx) {
                                final hasFocus = Focus.of(ctx).hasFocus;
                                return GestureDetector(
                                  onTap: () => _switchSeason(idx, seasonMovie),
                                  child: AnimatedScale(
                                    scale: hasFocus ? 1.06 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 108,
                                          height: 162,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: hasFocus
                                                  ? primary
                                                  : isSelected
                                                      ? primary.withValues(alpha: 0.7)
                                                      : Colors.white.withValues(alpha: 0.15),
                                              width: hasFocus ? 2.5 : isSelected ? 2 : 1,
                                            ),
                                            boxShadow: hasFocus
                                                ? [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 18, spreadRadius: 1)]
                                                : isSelected
                                                    ? [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 12)]
                                                    : null,
                                          ),
                                          child: Stack(
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: posterUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.white.withValues(alpha: 0.05),
                                                  child: const Center(
                                                    child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: Colors.white.withValues(alpha: 0.05),
                                                  child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 32),
                                                ),
                                                fadeInDuration: const Duration(milliseconds: 250),
                                                memCacheWidth: 220,
                                                memCacheHeight: 330,
                                              ),
                                              // Glassmorphism label at bottom
                                              Positioned(
                                                bottom: 0, left: 0, right: 0,
                                                child: ClipRect(
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            Colors.black.withValues(alpha: 0.3),
                                                            Colors.black.withValues(alpha: 0.75),
                                                          ],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        label,
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: isSelected ? primary : onSurface,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Cairo',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // الموسم الحالي badge
                                              if (isSelected)
                                                Positioned(
                                                  top: 6, left: 6,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: primary.withValues(alpha: 0.9),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'الحالي',
                                                          style: TextStyle(
                                                            color: onPrimary,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 9,
                                                            fontFamily: 'Cairo',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // focus overlay
                                              if (hasFocus)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(14),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          primary.withValues(alpha: 0.08),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ── فاصل ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── قائمة الحلقات ──
              if (_isSeasonLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                )
              else if (episodes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.videocam_off_rounded,
                            color: onSurfaceVar.withValues(alpha: 0.4), size: 52),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد حلقات متاحة لهذا الموسم',
                          style: TextStyle(
                              color: onSurfaceVar,
                              fontSize: 14,
                              fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: episodes.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 0.5,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final ep = episodes[index];
                      final epNum = ep.episodeNumber ?? index + 1;
                      final formattedTitle = _formatEpisodeTitle(ep, epNum);
                      return _EpisodeListRow(
                        episode: ep,
                        episodeNumber: epNum,
                        displayTitle: formattedTitle,
                        isTV: isTV,
                        seriesPosterUrl: movie.posterUrl,
                        onPlay: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              videoUrl: ep.videoUrl,
                              title: formattedTitle,
                              subtitleUrl: ep.subtitleUrl,
                              qualities: ep.videoQualities,
                              episodes: episodes,
                              currentEpisodeIndex: index,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        }),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isTV}) {
    final topPadding = isTV ? 0.0 : MediaQuery.of(context).padding.top;
    final height = isTV ? 64.0 : (60.0 + topPadding);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          padding: EdgeInsets.only(
            top: topPadding, left: 20, right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [background.withValues(alpha: 0.85), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              _TvIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              const Text('TVplus',
                  style: TextStyle(
                      color: primary, fontSize: 22,
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCastChip(String name, bool isPrimary) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: FutureBuilder<String?>(
        future: TmdbService.getActorImageUrl(name),
        builder: (_, snap) {
          final url = snap.data ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=2A2A2A&color=E5E2E1&bold=true&rounded=true';
          return Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isPrimary ? primary : outlineVar, width: 2),
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 6),
              Text(name.split(' ').first,
                  style: const TextStyle(
                      color: onSurface, fontSize: 12, fontFamily: 'Cairo')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuggestedSection(Movie movie, {required bool isTV}) {
    final similar = movie.similarMovies ?? [];
    if (similar.isEmpty) return const SizedBox.shrink();

    const title = 'قد يعجبك أيضاً';
    final sectionSize = isTV ? 22.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.video_library_rounded, color: primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: primary,
                fontSize: sectionSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isTV ? 230 : 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            itemBuilder: (context, index) {
              final sim = similar[index];
              return _SuggestedMovieCard(
                movie: sim,
                isTV: isTV,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsScreen(movie: sim),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// زر TV/موبايل قابل للفوكس — يدعم ريمونت TV وLمس الموبايل
// ══════════════════════════════════════════════════════════════
class _TvButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool autofocus;

  const _TvButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.autofocus = false,
  });

  @override
  __TvButtonState createState() => __TvButtonState();
}

class __TvButtonState extends State<_TvButton> {
  bool _focused = false;

  static const Color primary   = Color(0xFF00E5FF);
  static const Color onPrimary = Color(0xFF00373F);

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _focused ? primary : (widget.isPrimary ? primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _focused ? primary : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: _focused ? onPrimary : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(
                      color: _focused ? onPrimary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// زر أيقونة — TV وموبايل
// ══════════════════════════════════════════════════════════════
class _TvIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TvIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  __TvIconButtonState createState() => __TvIconButtonState();
}

class __TvIconButtonState extends State<_TvIconButton> {
  bool _focused = false;
  static const Color primary = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _focused ? primary.withValues(alpha: 0.2) : Colors.transparent,
            border: Border.all(
              color: _focused ? primary : Colors.white.withValues(alpha: 0.25),
              width: _focused ? 2 : 1,
            ),
          ),
          child: Icon(widget.icon,
              color: _focused ? primary : Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ودجت البوستر المحسّن — TV وموبايل
// ══════════════════════════════════════════════════════════════
class _PosterWidget extends StatefulWidget {
  final String posterUrl;
  final ChewieController? chewieController;
  final VoidCallback onTap;

  const _PosterWidget({
    required this.posterUrl,
    this.chewieController,
    required this.onTap,
  });

  @override
  __PosterWidgetState createState() => __PosterWidgetState();
}

class __PosterWidgetState extends State<_PosterWidget> {
  bool _focused = false;

  static const Color primary = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused ? primary : Colors.white.withValues(alpha: 0.1),
                width: _focused ? 3 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.chewieController != null
                  ? SizedBox(
                      height: 220,
                      child: OverflowBox(
                        maxHeight: 220,
                        alignment: Alignment.center,
                        child: Chewie(controller: widget.chewieController!),
                      ),
                    )
                  : Stack(
                      children: [
                        SizedBox(
                          height: 250,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: CachedNetworkImage(
                              imageUrl: widget.posterUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.white10,
                                child: const Center(
                                  child: CircularProgressIndicator(color: primary),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.movie_rounded,
                                  color: Colors.white24,
                                  size: 48,
                                ),
                              ),
                              fadeInDuration: const Duration(milliseconds: 300),
                              memCacheWidth: 400,
                              memCacheHeight: 600,
                            ),
                          ),
                        ),
                        if (_focused)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// بطاقة الحلقة العمودية — تصميم Glassmorphic احترافي
// ══════════════════════════════════════════════════════════════
class _EpisodeListRow extends StatefulWidget {
  final Episode episode;
  final int episodeNumber;
  final String displayTitle;
  final bool isTV;
  final String seriesPosterUrl;
  final VoidCallback onPlay;

  const _EpisodeListRow({
    required this.episode,
    required this.episodeNumber,
    required this.displayTitle,
    required this.isTV,
    required this.seriesPosterUrl,
    required this.onPlay,
  });

  @override
  _EpisodeListRowState createState() => _EpisodeListRowState();
}

class _EpisodeListRowState extends State<_EpisodeListRow> {
  bool _focused = false;

  static const Color primary      = Color(0xFF00E5FF);
  static const Color onPrimary    = Color(0xFF00373F);
  static const Color onSurface    = Color(0xFFF0EFFF);
  static const Color onSurfaceVar = Color(0xFFA59EC6);
  static const Color watchedColor = Color(0xFF4CAF50);

  Future<Map<String, int>> _getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getInt('progress_${widget.episode.videoUrl}') ?? 0;
    final duration = prefs.getInt('duration_${widget.episode.videoUrl}') ?? 0;
    return {'progress': progress, 'duration': duration};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getProgress(),
      builder: (context, snapshot) {
        final progress    = snapshot.data?['progress'] ?? 0;
        final duration    = snapshot.data?['duration'] ?? 0;
        final percent     = duration > 0 ? (progress / duration).clamp(0.0, 1.0) : 0.0;
        final isWatched   = percent > 0.9;
        final hasProgress = progress > 5 && percent > 0.01 && !isWatched;

        // اختر صورة الحلقة: إن وُجد thumbnailUrl استخدمه، وإلا بوستر المسلسل
        final thumbUrl = (widget.episode.thumbnailUrl?.isNotEmpty == true)
            ? widget.episode.thumbnailUrl!
            : widget.seriesPosterUrl;

        final thumbW = widget.isTV ? 148.0 : 118.0;
        final thumbH = widget.isTV ? 86.0  : 68.0;

        return Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent) {
              final k = event.logicalKey;
              if (k == LogicalKeyboardKey.select ||
                  k == LogicalKeyboardKey.enter ||
                  k == LogicalKeyboardKey.numpadEnter ||
                  k == LogicalKeyboardKey.space) {
                widget.onPlay();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: widget.onPlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(
                horizontal: widget.isTV ? 16 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: _focused
                    ? LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          primary.withValues(alpha: 0.18),
                          primary.withValues(alpha: 0.06),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focused
                      ? primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.08),
                  width: _focused ? 1.5 : 1,
                ),
                boxShadow: _focused
                    ? [BoxShadow(
                        color: primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      )]
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.isTV ? 10 : 8),
                child: Row(
                  children: [

                    // ── رقم الحلقة ──
                    SizedBox(
                      width: widget.isTV ? 44 : 36,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.episodeNumber.toString().padLeft(2, '0'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _focused ? primary : onSurfaceVar,
                              fontSize: widget.isTV ? 20 : 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (isWatched)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(Icons.check_circle_rounded,
                                  color: watchedColor, size: 13),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ── صورة مصغرة مع blur ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: thumbW,
                            height: thumbH,
                            child: CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.white.withValues(alpha: 0.06),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: primary, strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.white.withValues(alpha: 0.06),
                                child: Icon(Icons.movie_rounded,
                                    color: Colors.white24,
                                    size: widget.isTV ? 28 : 22),
                              ),
                              fadeInDuration: const Duration(milliseconds: 200),
                              memCacheWidth: 300,
                              memCacheHeight: 180,
                            ),
                          ),
                          // تدرج داكن فوق الصورة
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // أيقونة تشغيل في المنتصف
                          Positioned.fill(
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: widget.isTV ? 38 : 30,
                                height: widget.isTV ? 38 : 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _focused
                                      ? primary.withValues(alpha: 0.9)
                                      : Colors.black.withValues(alpha: 0.45),
                                  border: Border.all(
                                    color: _focused
                                        ? primary
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: _focused ? onPrimary : Colors.white,
                                  size: widget.isTV ? 22 : 17,
                                ),
                              ),
                            ),
                          ),
                          // badge مشاهَدة
                          if (isWatched)
                            Positioned(
                              top: 5, right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: watchedColor,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 9),
                              ),
                            ),
                          // شريط التقدم
                          if (hasProgress)
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: Colors.white12,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(primary),
                                minHeight: 3,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── معلومات الحلقة ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.displayTitle,
                            style: TextStyle(
                              color: _focused ? primary : onSurface,
                              fontSize: widget.isTV ? 15 : 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (widget.episode.fileSize.isNotEmpty)
                                _MetaBadge(
                                  icon: Icons.folder_outlined,
                                  label: widget.episode.fileSize,
                                  color: onSurfaceVar,
                                ),
                              if (widget.episode.videoQualities != null &&
                                  widget.episode.videoQualities!.isNotEmpty)
                                _MetaBadge(
                                  icon: Icons.hd_rounded,
                                  label: widget.episode.videoQualities!.keys.first,
                                  color: primary,
                                  highlighted: true,
                                ),
                              if (isWatched)
                                _MetaBadge(
                                  icon: Icons.check_circle_rounded,
                                  label: 'تمت المشاهدة',
                                  color: watchedColor,
                                )
                              else if (hasProgress)
                                _MetaBadge(
                                  icon: Icons.schedule_rounded,
                                  label: '${(percent * 100).toInt()}% مكتمل',
                                  color: primary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Badge صغير للميتاداتا ──
class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool highlighted;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: highlighted
          ? BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// كارت محتوى مقترح / مشابه — TV وموبايل
// ══════════════════════════════════════════════════════════════
class _SuggestedMovieCard extends StatefulWidget {
  final Movie movie;
  final bool isTV;
  final VoidCallback onTap;

  const _SuggestedMovieCard({
    required this.movie,
    required this.isTV,
    required this.onTap,
  });

  @override
  State<_SuggestedMovieCard> createState() => _SuggestedMovieCardState();
}

class _SuggestedMovieCardState extends State<_SuggestedMovieCard> {
  bool _focused = false;
  bool _hovered = false;

  static const Color primary = Color(0xFF00E5FF);
  static const Color onSurface = Color(0xFFF0EFFF);

  bool get _isHighlighted => _focused || _hovered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent) {
              final k = event.logicalKey;
              if (k == LogicalKeyboardKey.select ||
                  k == LogicalKeyboardKey.enter ||
                  k == LogicalKeyboardKey.numpadEnter ||
                  k == LogicalKeyboardKey.space) {
                widget.onTap();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isHighlighted ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: widget.isTV ? 110 : 100,
                    height: widget.isTV ? 165 : 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isHighlighted 
                            ? primary 
                            : Colors.white.withValues(alpha: 0.12),
                        width: _isHighlighted ? 2.5 : 1,
                      ),
                      boxShadow: _isHighlighted
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 15,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.white10,
                              child: const Center(
                                child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 32),
                            ),
                            fadeInDuration: const Duration(milliseconds: 250),
                            memCacheWidth: 220,
                            memCacheHeight: 330,
                          ),
                          if (_isHighlighted)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.15),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: widget.isTV ? 110 : 100,
                    child: Text(
                      widget.movie.title,
                      style: const TextStyle(
                        color: onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
