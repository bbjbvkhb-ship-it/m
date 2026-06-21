
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/netflix_theme.dart';

/// شاشة المشغل بتصميم Netflix
class NetflixPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitleUrl;
  final bool isLive;

  const NetflixPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.title,
    this.subtitleUrl,
    this.isLive = false,
  }) : super(key: key);

  @override
  _NetflixPlayerScreenState createState() => _NetflixPlayerScreenState();
}

class _NetflixPlayerScreenState extends State<NetflixPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  bool _isPlayerInitialized = false;
  bool _showControls = true;
  bool _isPlaying = false;

  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _rewindFocusNode = FocusNode();
  final FocusNode _forwardFocusNode = FocusNode();
  final FocusNode _backFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initPlayer();

    // إخفاء عناصر التحكم بعد 4 ثواني
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });

    // طلب التركيز التلقائي على زر التشغيل/الإيقاف
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _playPauseFocusNode.canRequestFocus) {
        _playPauseFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _playPauseFocusNode.dispose();
    _rewindFocusNode.dispose();
    _forwardFocusNode.dispose();
    _backFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
      }

      _videoPlayerController.play();
      setState(() {
        _isPlaying = true;
      });

      _videoPlayerController.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoPlayerController.value.isPlaying;
          });
        }
      });
    } catch (e) {
      print('Error initializing player: $e');
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _rewind() {
    final currentPosition = _videoPlayerController.value.position;
    _videoPlayerController.seekTo(
      currentPosition - const Duration(seconds: 10),
    );
  }

  void _forward() {
    final currentPosition = _videoPlayerController.value.position;
    _videoPlayerController.seekTo(
      currentPosition + const Duration(seconds: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 700;

    if (!_isPlayerInitialized) {
      return Scaffold(
        backgroundColor: NetflixTheme.netflixBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: NetflixTheme.netflixRed,
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل الفيديو...',
                style: TextStyle(
                  color: NetflixTheme.netflixWhite,
                  fontSize: isTV ? 20 : 16,
                  fontFamily: 'NetflixSans',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NetflixTheme.netflixBlack,
      body: Stack(
        children: [
          // مشغل الفيديو
          Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController),
            ),
          ),

          // عناصر التحكم
          if (_showControls)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // شريط علوي
                    _buildTopBar(isTV),

                    // أزرار التحكم
                    _buildControls(isTV),
                  ],
                ),
              ),
            ),

          // زر التشغيل/الإيقاف في المنتصف
          if (!_showControls && !_isPlaying)
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = true;
                    _togglePlayPause();
                  });
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NetflixTheme.netflixRed.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: NetflixTheme.netflixWhite,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isTV) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTV ? 48 : 24,
        vertical: isTV ? 24 : 16,
      ),
      child: Row(
        children: [
          // زر العودة
          _buildControlButton(
            focusNode: _backFocusNode,
            icon: Icons.arrow_back,
            isTV: isTV,
            onPressed: () => Navigator.pop(context),
          ),

          const SizedBox(width: 16),

          // عنوان الفيديو
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: NetflixTheme.netflixWhite,
                fontSize: isTV ? 20 : 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NetflixSans',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isTV) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTV ? 48 : 24,
        vertical: isTV ? 32 : 24,
      ),
      child: Column(
        children: [
          // شريط التقدم (للبث المسجل فقط)
          if (!widget.isLive)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTV ? 48 : 24),
              child: VideoProgressIndicator(
                _videoPlayerController,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: NetflixTheme.netflixRed,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),

          if (!widget.isLive)
            SizedBox(height: isTV ? 24 : 16),

          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر الترجيع
              _buildControlButton(
                focusNode: _rewindFocusNode,
                icon: Icons.replay_10,
                isTV: isTV,
                onPressed: _rewind,
              ),

              SizedBox(width: isTV ? 48 : 32),

              // زر التشغيل/الإيقاف
              _buildControlButton(
                focusNode: _playPauseFocusNode,
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                isTV: isTV,
                isLarge: true,
                onPressed: _togglePlayPause,
              ),

              SizedBox(width: isTV ? 48 : 32),

              // زر التقديم
              _buildControlButton(
                focusNode: _forwardFocusNode,
                icon: Icons.forward_10,
                isTV: isTV,
                onPressed: _forward,
              ),
            ],
          ),

          // معلومات الوقت (للبث المسجل فقط)
          if (!widget.isLive)
            Padding(
              padding: EdgeInsets.only(top: isTV ? 16 : 8),
              child: _buildTimeInfo(isTV),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required FocusNode focusNode,
    required IconData icon,
    required bool isTV,
    required VoidCallback onPressed,
    bool isLarge = false,
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
              width: isLarge ? (isTV ? 80 : 64) : (isTV ? 64 : 48),
              height: isLarge ? (isTV ? 80 : 64) : (isTV ? 64 : 48),
              decoration: BoxDecoration(
                color: hasFocus 
                    ? NetflixTheme.netflixWhite 
                    : Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasFocus ? NetflixTheme.netflixRed : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: hasFocus 
                    ? NetflixTheme.netflixBlack 
                    : NetflixTheme.netflixWhite,
                size: isLarge ? (isTV ? 40 : 32) : (isTV ? 32 : 24),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(bool isTV) {
    final position = _videoPlayerController.value.position;
    final duration = _videoPlayerController.value.duration;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDuration(position),
          style: TextStyle(
            color: NetflixTheme.netflixWhite,
            fontSize: isTV ? 16 : 14,
            fontFamily: 'NetflixSans',
          ),
        ),
        Text(
          ' / ',
          style: TextStyle(
            color: NetflixTheme.netflixLightGray,
            fontSize: isTV ? 16 : 14,
            fontFamily: 'NetflixSans',
          ),
        ),
        Text(
          _formatDuration(duration),
          style: TextStyle(
            color: NetflixTheme.netflixLightGray,
            fontSize: isTV ? 16 : 14,
            fontFamily: 'NetflixSans',
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
