import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Subtitle model
// ─────────────────────────────────────────────
class Subtitle {
  final Duration start;
  final Duration end;
  final String text;
  const Subtitle({required this.start, required this.end, required this.text});
}

// ─────────────────────────────────────────────
// PlayerScreen widget
// ─────────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitleUrl;
  final bool isLive;
  final Map<String, String>? qualities;
  final List<Episode>? episodes;
  final int? currentEpisodeIndex;

  const PlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.subtitleUrl,
    this.isLive = false,
    this.qualities,
    this.episodes,
    this.currentEpisodeIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  // ── Video controller ──
  late VideoPlayerController _controller;
  bool _initialized = false;

  // ── UI state ──
  bool _showControls = true;
  bool _showEpisodes = false;
  bool _showQuality = false;
  bool _isMuted = false;
  bool _subtitlesOn = true;
  double _subFontSize = 22.0;
  String _aspectMode = 'default'; // default | stretch | 16_9 | 4_3

  // ── Skip intro ──
  bool _showSkipIntro = false;
  bool _introSkipped = false;

  // ── Scrubbing ──
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;
  Timer? _scrubTimer;

  // ── Episodes & Quality ──
  List<Episode> _episodes = [];
  int? _epIndex;
  late Map<String, String> _qualities;
  late String _qualityKey;
  late String _videoUrl;

  // ── Subtitles ──
  List<Subtitle> _subs = [];
  Subtitle? _activeSub;
  int _lastSavedSec = -1;

  // ── Auto-hide timer ──
  Timer? _hideTimer;

  // ── Next episode guard ──
  bool _nextEpGuard = false;

  // ── Focus nodes ──
  final FocusNode _rootFocus = FocusNode();
  final FocusNode _backFocus = FocusNode();
  final FocusNode _rewindFocus = FocusNode();
  final FocusNode _playFocus = FocusNode();
  final FocusNode _forwardFocus = FocusNode();
  final FocusNode _seekFocus = FocusNode();
  final FocusNode _muteFocus = FocusNode();
  final FocusNode _ccFocus = FocusNode();
  final FocusNode _subSizeFocus = FocusNode();
  final FocusNode _epsFocus = FocusNode();
  final FocusNode _qualityFocus = FocusNode();
  final FocusNode _aspectFocus = FocusNode();
  final FocusNode _skipFocus = FocusNode();

  static const _cyan = Color(0xFF00E5FF);
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Referer': 'https://movie.vodu.me/',
  };

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _videoUrl = widget.videoUrl;
    _qualities = Map.from(widget.qualities ?? {});
    if (_qualities.isEmpty) _qualities['Default'] = _videoUrl;
    _qualityKey = _qualities.entries
        .firstWhere((e) => e.value.trim() == _videoUrl.trim(),
            orElse: () => _qualities.entries.first)
        .key;
    _episodes = widget.episodes ?? [];
    _epIndex = widget.currentEpisodeIndex;
    _initPlayer();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    WakelockPlus.disable();
    _hideTimer?.cancel();
    _scrubTimer?.cancel();
    if (_initialized) {
      if (!widget.isLive) _controller.removeListener(_onVideoTick);
      _controller.dispose();
    }
    _rootFocus.dispose();
    _backFocus.dispose();
    _rewindFocus.dispose();
    _playFocus.dispose();
    _forwardFocus.dispose();
    _seekFocus.dispose();
    _muteFocus.dispose();
    _ccFocus.dispose();
    _subSizeFocus.dispose();
    _epsFocus.dispose();
    _qualityFocus.dispose();
    _aspectFocus.dispose();
    _skipFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Player initialisation
  // ─────────────────────────────────────────────
  Future<void> _initPlayer({int savedSecs = -1}) async {
    if (!widget.isLive &&
        widget.subtitleUrl != null &&
        widget.subtitleUrl!.isNotEmpty) {
      await _loadSubtitles(widget.subtitleUrl!);
    }

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(_videoUrl.trim()),
      httpHeaders: _headers,
    );

    int resumeSecs = savedSecs;
    if (!widget.isLive && resumeSecs < 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        resumeSecs = prefs.getInt('progress_${widget.videoUrl}') ?? 0;
        final dur = prefs.getInt('duration_${widget.videoUrl}') ?? 0;
        if (dur > 0 && (resumeSecs / dur) > 0.95) resumeSecs = 0;
      } catch (_) {}
    }

    try {
      await _controller.initialize();
      if (resumeSecs > 5) {
        await _controller.seekTo(Duration(seconds: resumeSecs));
      }
      if (!widget.isLive) _controller.addListener(_onVideoTick);
      _controller.setVolume(_isMuted ? 0 : 1);
      _controller.play();
      await WakelockPlus.enable();
      if (!mounted) return;
      setState(() => _initialized = true);
      _showControlsAndFocus();
    } catch (e) {
      debugPrint('Player init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل تشغيل الفيديو: $e',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Video listener (subtitles, next ep, skip intro)
  // ─────────────────────────────────────────────
  void _onVideoTick() {
    if (!mounted || widget.isLive) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    _saveProgress(pos);

    // Auto next episode
    if (dur.inSeconds > 0 &&
        pos.inSeconds >= dur.inSeconds - 1 &&
        !_controller.value.isPlaying) {
      if (_epIndex != null && _epIndex! + 1 < _episodes.length) {
        if (!_nextEpGuard) {
          _nextEpGuard = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            _nextEpGuard = false;
            _playEp(_epIndex! + 1);
          });
        }
        return;
      }
    }

    // Subtitles
    Subtitle? found;
    if (_subs.isNotEmpty && _subtitlesOn) {
      for (final s in _subs) {
        if (pos >= s.start && pos <= s.end) {
          found = s;
          break;
        }
      }
    }
    if (_activeSub != found) setState(() => _activeSub = found);

    // Skip intro window: 1s – 85s
    final inIntroWindow = pos.inSeconds >= 1 && pos.inSeconds < 85;
    if (inIntroWindow && !_introSkipped) {
      if (!_showSkipIntro) setState(() => _showSkipIntro = true);
    } else if (pos.inSeconds >= 85 && _showSkipIntro) {
      setState(() => _showSkipIntro = false);
    }
  }

  Future<void> _saveProgress(Duration pos) async {
    if (widget.isLive) return;
    final sec = pos.inSeconds;
    if (sec == _lastSavedSec) return;
    _lastSavedSec = sec;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('progress_${widget.videoUrl}', sec);
      final dur = _controller.value.duration.inSeconds;
      if (dur > 0) await prefs.setInt('duration_${widget.videoUrl}', dur);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Controls visibility
  // ─────────────────────────────────────────────
  void _showControlsAndFocus() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _resetHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showControls && !_anyControlHasFocus()) {
        if (_playFocus.canRequestFocus) _playFocus.requestFocus();
      }
    });
  }

  bool _anyControlHasFocus() =>
      _backFocus.hasFocus ||
      _rewindFocus.hasFocus ||
      _playFocus.hasFocus ||
      _forwardFocus.hasFocus ||
      _seekFocus.hasFocus ||
      _muteFocus.hasFocus ||
      _ccFocus.hasFocus ||
      _subSizeFocus.hasFocus ||
      _epsFocus.hasFocus ||
      _qualityFocus.hasFocus ||
      _aspectFocus.hasFocus ||
      _skipFocus.hasFocus;

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_showEpisodes || _showQuality) return;
    _hideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _showControls = false);
        _rootFocus.requestFocus();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Playback actions
  // ─────────────────────────────────────────────
  void _togglePlay() {
    if (!_initialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
    _showControlsAndFocus();
  }

  void _seek(int deltaSecs) {
    if (!_initialized || widget.isLive) return;
    _scrubTimer?.cancel();
    _resetHideTimer();
    setState(() {
      if (!_isScrubbing) {
        _isScrubbing = true;
        _scrubPosition = _controller.value.position;
      }
      final dur = _controller.value.duration;
      final next = _scrubPosition.inSeconds + deltaSecs;
      _scrubPosition = Duration(seconds: next.clamp(0, dur.inSeconds));
    });
    _scrubTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.seekTo(_scrubPosition);
        setState(() => _isScrubbing = false);
      }
    });
  }

  void _toggleMute() {
    if (!_initialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
    _toast(_isMuted ? 'كتم الصوت' : 'تشغيل الصوت',
        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded);
  }

  void _toggleCC() {
    setState(() {
      _subtitlesOn = !_subtitlesOn;
      if (!_subtitlesOn) _activeSub = null;
    });
    _toast(_subtitlesOn ? 'تم تفعيل الترجمة' : 'تم إيقاف الترجمة',
        Icons.subtitles_rounded);
  }

  void _cycleSubSize() {
    setState(() {
      if (_subFontSize == 18) {
        _subFontSize = 22;
      } else if (_subFontSize == 22) {
        _subFontSize = 26;
      } else if (_subFontSize == 26) {
        _subFontSize = 30;
      } else {
        _subFontSize = 18;
      }
    });
    final label = {18.0: 'صغير', 22.0: 'متوسط', 26.0: 'كبير', 30.0: 'ضخم'}[_subFontSize]!;
    _toast('حجم الترجمة: $label', Icons.text_fields_rounded);
  }

  void _cycleAspect() {
    setState(() {
      _aspectMode = switch (_aspectMode) {
        'default' => 'stretch',
        'stretch' => '16_9',
        '16_9' => '4_3',
        _ => 'default',
      };
    });
    final label = {
      'default': 'تلقائي',
      'stretch': 'ملء الشاشة',
      '16_9': '16:9',
      '4_3': '4:3'
    }[_aspectMode]!;
    _toast('وضع العرض: $label', Icons.aspect_ratio_rounded);
  }

  void _skipIntro() {
    if (widget.isLive) return;
    _controller.seekTo(const Duration(seconds: 90));
    setState(() {
      _showSkipIntro = false;
      _introSkipped = true;
    });
    _toast('تم تخطي المقدمة', Icons.skip_next_rounded);
  }

  Future<void> _changeQuality(String key, String url) async {
    if (key == _qualityKey || !_initialized) return;
    final pos = _controller.value.position;
    final wasPlaying = _controller.value.isPlaying;

    setState(() {
      _qualityKey = key;
      _videoUrl = url;
      _initialized = false;
    });

    if (!widget.isLive) _controller.removeListener(_onVideoTick);
    await _controller.dispose();

    _controller = VideoPlayerController.networkUrl(
        Uri.parse(url.trim()),
        httpHeaders: _headers);
    try {
      await _controller.initialize();
      await _controller.seekTo(pos);
      if (!widget.isLive) _controller.addListener(_onVideoTick);
      _controller.setVolume(_isMuted ? 0 : 1);
      if (wasPlaying) _controller.play();
      if (!mounted) return;
      setState(() => _initialized = true);
      _toast('الجودة: $key', Icons.hd_rounded);
    } catch (e) {
      debugPrint('Quality change error: $e');
    }
  }

  Future<void> _playEp(int index) async {
    if (index < 0 || index >= _episodes.length) return;
    final ep = _episodes[index];
    if (_initialized) await _saveProgress(_controller.value.position);

    setState(() {
      _epIndex = index;
      _videoUrl = ep.videoUrl;
      _qualities = ep.videoQualities ?? {'Default': ep.videoUrl};
      _qualityKey = _qualities.keys.first;
      _initialized = false;
      _introSkipped = false;
      _showSkipIntro = false;
      _showEpisodes = false;
    });

    if (!widget.isLive) _controller.removeListener(_onVideoTick);
    await _controller.dispose();

    _controller = VideoPlayerController.networkUrl(
        Uri.parse(_videoUrl.trim()),
        httpHeaders: _headers);

    if (ep.subtitleUrl != null && ep.subtitleUrl!.isNotEmpty) {
      await _loadSubtitles(ep.subtitleUrl!);
    } else {
      _subs = [];
      _activeSub = null;
    }

    try {
      await _controller.initialize();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('progress_${ep.videoUrl}') ?? 0;
      if (saved > 5) await _controller.seekTo(Duration(seconds: saved));
      if (!widget.isLive) _controller.addListener(_onVideoTick);
      _controller.setVolume(_isMuted ? 0 : 1);
      _controller.play();
      if (!mounted) return;
      setState(() => _initialized = true);
      _toast(
          'جاري تشغيل: ${ep.title.isNotEmpty ? ep.title : "الحلقة ${index + 1}"}',
          Icons.play_circle_fill_rounded);
    } catch (e) {
      debugPrint('Episode play error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Subtitles
  // ─────────────────────────────────────────────
  Future<void> _loadSubtitles(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return;
      final text = utf8.decode(res.bodyBytes, allowMalformed: true);
      final lines = text.split('\n');
      final List<Subtitle> list = [];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.contains('-->')) continue;
        final parts = line.split('-->');
        if (parts.length != 2) continue;
        final start = _parseTime(parts[0].trim());
        final end = _parseTime(parts[1].trim());
        StringBuffer buf = StringBuffer();
        i++;
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          final clean = lines[i].trim().replaceAll(RegExp(r'<[^>]*>'), '');
          if (buf.isNotEmpty) buf.write('\n');
          buf.write(clean);
          i++;
        }
        if (buf.isNotEmpty) {
          list.add(Subtitle(start: start, end: end, text: buf.toString()));
        }
      }
      setState(() => _subs = list);
    } catch (e) {
      debugPrint('Subtitle load error: $e');
    }
  }

  Duration _parseTime(String s) {
    final parts = s.split(':');
    int h = 0, m = 0;
    double sec = 0;
    if (parts.length == 3) {
      h = int.tryParse(parts[0]) ?? 0;
      m = int.tryParse(parts[1]) ?? 0;
      sec = double.tryParse(parts[2].replaceAll(',', '.')) ?? 0;
    } else if (parts.length == 2) {
      m = int.tryParse(parts[0]) ?? 0;
      sec = double.tryParse(parts[1].replaceAll(',', '.')) ?? 0;
    }
    return Duration(
      hours: h,
      minutes: m,
      seconds: sec.truncate(),
      milliseconds: ((sec - sec.truncate()) * 1000).round(),
    );
  }

  // ─────────────────────────────────────────────
  // Key handler (global D-pad)
  // ─────────────────────────────────────────────
  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;

    // Handle back/escape/backspace keys globally for closing drawer/picker or popping
    final isBackKey = k == LogicalKeyboardKey.goBack ||
        k == LogicalKeyboardKey.escape ||
        k == LogicalKeyboardKey.backspace;

    if (isBackKey) {
      if (_showQuality) {
        setState(() => _showQuality = false);
        _qualityFocus.requestFocus();
        _resetHideTimer();
        return KeyEventResult.handled;
      }
      if (_showEpisodes) {
        setState(() => _showEpisodes = false);
        _epsFocus.requestFocus();
        _resetHideTimer();
        return KeyEventResult.handled;
      }
      // Let PopScope / Navigator handle back navigation to exit the player
      return KeyEventResult.ignored;
    }

    if (_showQuality) return KeyEventResult.ignored;

    // When controls are hidden, any key shows them
    if (!_showControls) {
      _showControlsAndFocus();
      if (k == LogicalKeyboardKey.arrowLeft) {
        _seekFocus.requestFocus();
        _seek(-15);
      } else if (k == LogicalKeyboardKey.arrowRight) {
        _seekFocus.requestFocus();
        _seek(15);
      } else if (k == LogicalKeyboardKey.space ||
                 k == LogicalKeyboardKey.enter ||
                 k == LogicalKeyboardKey.select ||
                 k == LogicalKeyboardKey.numpadEnter ||
                 k == LogicalKeyboardKey.mediaPlay ||
                 k == LogicalKeyboardKey.mediaPause ||
                 k == LogicalKeyboardKey.mediaPlayPause) {
        _togglePlay();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _toast(String msg, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 2),
      content: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: _cyan.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: _cyan, size: 18),
                const SizedBox(width: 8),
                Text(msg,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              ]),
            ),
          ),
        ),
      ),
    ));
  }

  // ─────────────────────────────────────────────
  // VIDEO WIDGET
  // ─────────────────────────────────────────────
  Widget _buildVideo() {
    if (!_initialized) {
      return const Center(
          child: CircularProgressIndicator(color: _cyan, strokeWidth: 2));
    }
    if (_aspectMode == 'stretch') {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    }
    double ratio;
    if (_aspectMode == '16_9') {
      ratio = 16 / 9;
    } else if (_aspectMode == '4_3') {
      ratio = 4 / 3;
    } else {
      ratio = _initialized ? _controller.value.aspectRatio : 16 / 9;
    }
    return Center(
      child: AspectRatio(aspectRatio: ratio, child: VideoPlayer(_controller)),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.isLive)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: const Text('مباشر',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
            ),
          Flexible(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                shadows: [Shadow(color: Colors.black, blurRadius: 12)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 14),
          _iconBtn(
            focusNode: _backFocus,
            icon: Icons.arrow_forward_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CENTER PLAY BUTTON (shown only when paused)
  // ─────────────────────────────────────────────
  Widget _buildCenterPlay() {
    if (!_initialized || _controller.value.isPlaying) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 20)],
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    final hasEps = _episodes.isNotEmpty && _epIndex != null;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.black.withValues(alpha: 0.5),
          child: Row(children: [
            // Rewind
            _iconBtn(
                focusNode: _rewindFocus,
                icon: Icons.fast_rewind_rounded,
                onTap: () => _seek(-15)),
            const SizedBox(width: 12),
            // Play/Pause
            _playPauseBtn(),
            const SizedBox(width: 12),
            // Forward
            _iconBtn(
                focusNode: _forwardFocus,
                icon: Icons.fast_forward_rounded,
                onTap: () => _seek(15)),
            const SizedBox(width: 14),
            // Seek bar
            Expanded(child: _buildSeekBar()),
            const SizedBox(width: 14),
            // Duration
            if (_initialized && !widget.isLive) _buildDuration(),
            const SizedBox(width: 16),
            // Mute
            _iconBtn(
                focusNode: _muteFocus,
                icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                onTap: _toggleMute),
            const SizedBox(width: 10),
            // CC
            _ccBtn(),
            const SizedBox(width: 10),
            // Subtitle size
            _iconBtn(
                focusNode: _subSizeFocus,
                icon: Icons.text_fields_rounded,
                onTap: _cycleSubSize),
            const SizedBox(width: 10),
            // Episodes
            if (hasEps) ...[
              _iconBtn(
                  focusNode: _epsFocus,
                  icon: Icons.playlist_play_rounded,
                  onTap: () {
                    setState(() => _showEpisodes = !_showEpisodes);
                    _resetHideTimer();
                  },
                  active: _showEpisodes),
              const SizedBox(width: 10),
            ],
            // Quality
            _iconBtn(
                focusNode: _qualityFocus,
                icon: Icons.settings_rounded,
                onTap: () {
                  setState(() => _showQuality = true);
                  _resetHideTimer();
                }),
            const SizedBox(width: 10),
            // Aspect ratio
            _iconBtn(
                focusNode: _aspectFocus,
                icon: Icons.aspect_ratio_rounded,
                onTap: _cycleAspect),
          ]),
        ),
      ),
    );
  }

  // ── Seek bar ──
  Widget _buildSeekBar() {
    return Focus(
      focusNode: _seekFocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _seek(-15);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _seek(15);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focus = Focus.of(ctx).hasFocus;
        if (!_initialized) return const SizedBox.shrink();
        final pos = _isScrubbing
            ? _scrubPosition
            : _controller.value.position;
        final dur = _controller.value.duration;
        final pct =
            dur.inSeconds > 0 ? (pos.inSeconds / dur.inSeconds).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          onTapDown: (d) {
            final box = ctx.findRenderObject() as RenderBox;
            final w = box.size.width;
            if (w > 0 && dur.inSeconds > 0) {
              final t = (d.localPosition.dx / w).clamp(0.0, 1.0);
              _controller.seekTo(Duration(seconds: (t * dur.inSeconds).round()));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth;
              return Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
                // Track
                Container(
                    height: focus ? 6 : 3,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4))),
                // Progress
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                      height: focus ? 6 : 3,
                      decoration: BoxDecoration(
                          color: _cyan,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: focus
                              ? [BoxShadow(color: _cyan.withValues(alpha: 0.5), blurRadius: 8)]
                              : null)),
                ),
                // Thumb
                Positioned(
                  left: (pct * w) - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: focus
                          ? [const BoxShadow(color: _cyan, blurRadius: 6, spreadRadius: 2)]
                          : null,
                    ),
                  ),
                ),
              ]);
            }),
          ),
        );
      }),
    );
  }

  // ── Duration text ──
  Widget _buildDuration() {
    final pos = _isScrubbing ? _scrubPosition : _controller.value.position;
    final dur = _controller.value.duration;
    return Text(
      '${_fmt(pos)} / ${_fmt(dur)}',
      style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo'),
    );
  }

  // ─────────────────────────────────────────────
  // SKIP INTRO BUTTON
  // ─────────────────────────────────────────────
  Widget _buildSkipIntroBtn() {
    return Focus(
      focusNode: _skipFocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            _skipIntro();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focus = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: _skipIntro,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: focus ? _cyan.withValues(alpha: 0.2) : Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: focus ? _cyan : Colors.white60, width: focus ? 2 : 1),
              boxShadow: focus
                  ? [BoxShadow(color: _cyan.withValues(alpha: 0.4), blurRadius: 16)]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.skip_next_rounded,
                  color: focus ? _cyan : Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('تخطي المقدمة',
                  style: TextStyle(
                      color: focus ? _cyan : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
            ]),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // SCRUBBING OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildScrubbingOverlay() {
    final dur = _initialized ? _controller.value.duration : Duration.zero;
    final pct = dur.inSeconds > 0
        ? (_scrubPosition.inSeconds / dur.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                _fmt(_scrubPosition),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(_cyan),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(_fmt(dur),
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontFamily: 'Cairo')),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EPISODES DRAWER
  // ─────────────────────────────────────────────
  Widget _buildEpisodesDrawer() {
    return Positioned(
      bottom: 62,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('قائمة الحلقات',
                          style: TextStyle(
                              color: _cyan,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo')),
                      Text('اضغط BACK للإغلاق',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontFamily: 'Cairo')),
                    ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _episodes.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _buildEpCard(_episodes[i], i, i == _epIndex),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEpCard(Episode ep, int i, bool current) {
    return FutureBuilder<Map<String, int>>(
      future: _epProgress(ep.videoUrl),
      builder: (_, snap) {
        final prog = snap.data?['p'] ?? 0;
        final dur = snap.data?['d'] ?? 0;
        final pct = dur > 0 ? (prog / dur).clamp(0.0, 1.0) : 0.0;
        final showPct = prog > 5 && pct > 0.01;

        return Focus(
          autofocus: current,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent) {
              final k = event.logicalKey;
              if (k == LogicalKeyboardKey.enter ||
                  k == LogicalKeyboardKey.select ||
                  k == LogicalKeyboardKey.numpadEnter) {
                _playEp(i);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (ctx) {
            final focus = Focus.of(ctx).hasFocus;
            return GestureDetector(
              onTap: () => _playEp(i),
              child: AnimatedScale(
                scale: focus ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 148,
                  decoration: BoxDecoration(
                    color: current
                        ? _cyan.withValues(alpha: 0.08)
                        : (focus ? Colors.white12 : Colors.black54),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: focus
                            ? _cyan
                            : (current
                                ? _cyan.withValues(alpha: 0.5)
                                : Colors.white24),
                        width: focus ? 2.5 : 1),
                  ),
                  child: Column(children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white10,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(9)),
                        ),
                        alignment: Alignment.center,
                        child: current
                            ? Text('جاري التشغيل',
                                style: TextStyle(
                                    color: _cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo'))
                            : const Icon(Icons.play_circle_outline_rounded,
                                color: Colors.white24, size: 28),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.title.isNotEmpty ? ep.title : 'الحلقة ${i + 1}',
                              style: TextStyle(
                                  color: current ? _cyan : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (showPct) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      current ? _cyan : Colors.white70),
                                  minHeight: 2,
                                ),
                              ),
                            ],
                          ]),
                    ),
                  ]),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Future<Map<String, int>> _epProgress(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'p': prefs.getInt('progress_$url') ?? 0,
      'd': prefs.getInt('duration_$url') ?? 0,
    };
  }

  // ─────────────────────────────────────────────
  // QUALITY OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildQualityOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() => _showQuality = false);
          _qualityFocus.requestFocus();
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _cyan.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('جودة الفيديو',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                    const SizedBox(height: 18),
                    ..._qualities.keys.toList().asMap().entries.map((e) {
                      final key = e.value;
                      final sel = key == _qualityKey;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Focus(
                          autofocus: sel,
                          onKeyEvent: (_, ev) {
                            if (ev is KeyDownEvent) {
                              final k = ev.logicalKey;
                              if (k == LogicalKeyboardKey.enter ||
                                  k == LogicalKeyboardKey.select ||
                                  k == LogicalKeyboardKey.numpadEnter) {
                                _changeQuality(key, _qualities[key]!);
                                setState(() => _showQuality = false);
                                _qualityFocus.requestFocus();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(builder: (ctx) {
                            final focus = Focus.of(ctx).hasFocus;
                            return GestureDetector(
                              onTap: () {
                                _changeQuality(key, _qualities[key]!);
                                setState(() => _showQuality = false);
                                _qualityFocus.requestFocus();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: focus
                                      ? _cyan.withValues(alpha: 0.18)
                                      : (sel
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.transparent),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: focus
                                        ? _cyan
                                        : (sel
                                            ? _cyan.withValues(alpha: 0.3)
                                            : Colors.transparent),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(key,
                                          style: TextStyle(
                                              color: focus
                                                  ? _cyan
                                                  : (sel
                                                      ? Colors.white
                                                      : Colors.white70),
                                              fontSize: 15,
                                              fontWeight: sel || focus
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontFamily: 'Cairo')),
                                      if (sel)
                                        const Icon(Icons.check_circle_rounded,
                                            color: _cyan, size: 18),
                                    ]),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    // Cancel button
                    Focus(
                      onKeyEvent: (_, ev) {
                        if (ev is KeyDownEvent) {
                          final k = ev.logicalKey;
                          if (k == LogicalKeyboardKey.enter ||
                              k == LogicalKeyboardKey.select ||
                              k == LogicalKeyboardKey.numpadEnter) {
                            setState(() => _showQuality = false);
                            _qualityFocus.requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(builder: (ctx) {
                        final focus = Focus.of(ctx).hasFocus;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _showQuality = false);
                            _qualityFocus.requestFocus();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: focus
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: focus ? Colors.white38 : Colors.white12,
                                  width: 1),
                            ),
                            child: const Text('إلغاء',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Cairo')),
                          ),
                        );
                      }),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE ICON BUTTON
  // ─────────────────────────────────────────────
  Widget _iconBtn({
    required FocusNode focusNode,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focus = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: focus
                  ? _cyan.withValues(alpha: 0.22)
                  : (active ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: focus || active ? _cyan : Colors.transparent, width: 1),
            ),
            child: Icon(icon,
                color: focus || active ? _cyan : Colors.white, size: 22),
          ),
        );
      }),
    );
  }

  Widget _playPauseBtn() {
    return Focus(
      focusNode: _playFocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            _togglePlay();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focus = Focus.of(ctx).hasFocus;
        final playing = _initialized && _controller.value.isPlaying;
        return GestureDetector(
          onTap: _togglePlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: focus ? _cyan.withValues(alpha: 0.22) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: focus ? _cyan : Colors.transparent, width: 1),
            ),
            child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: focus ? _cyan : Colors.white,
                size: 22),
          ),
        );
      }),
    );
  }

  Widget _ccBtn() {
    return Focus(
      focusNode: _ccFocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.numpadEnter ||
              k == LogicalKeyboardKey.space) {
            _toggleCC();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focus = Focus.of(ctx).hasFocus;
        final on = _subtitlesOn && _subs.isNotEmpty;
        return GestureDetector(
          onTap: _toggleCC,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: on ? Colors.red : (focus ? _cyan.withValues(alpha: 0.2) : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: focus ? _cyan : Colors.white, width: 1.5),
            ),
            child: const Text('CC',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo')),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasEps = _episodes.isNotEmpty && _epIndex != null;
    final bottomOffset =
        _showControls ? (_showEpisodes ? 248.0 : 78.0) : 38.0;

    return PopScope(
      canPop: !_showQuality && !_showEpisodes,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showQuality) {
          setState(() => _showQuality = false);
          _qualityFocus.requestFocus();
        } else if (_showEpisodes) {
          setState(() => _showEpisodes = false);
          _epsFocus.requestFocus();
        }
      },
      child: Focus(
        focusNode: _rootFocus,
        autofocus: true,
        onKeyEvent: (node, event) {
          _resetHideTimer();
          return _handleKey(event);
        },
        child: GestureDetector(
          onTap: () {
            if (_showControls) {
              setState(() {
                _showControls = false;
                _showEpisodes = false;
              });
              _rootFocus.requestFocus();
            } else {
              _showControlsAndFocus();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(children: [
              // ── Video ──
              _buildVideo(),

              // ── Controls overlay (auto-hide) ──
              IgnorePointer(
                ignoring: !_showControls,
                child: Focus(
                  descendantsAreFocusable: _showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Stack(children: [
                      // Gradient dimmer
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                              stops: const [0, 0.25, 0.7, 1],
                            ),
                          ),
                        ),
                      ),
                      // Top bar
                      Positioned(
                          top: 0, left: 0, right: 0, child: _buildTopBar()),
                      // Center play
                      Center(child: _buildCenterPlay()),
                      // Bottom bar
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildBottomBar()),
                    ]),
                  ),
                ),
              ),

              // ── Skip intro ──
              if (!widget.isLive && _showSkipIntro)
                Positioned(
                  bottom: bottomOffset + 12,
                  right: 40,
                  child: _buildSkipIntroBtn(),
                ),

              // ── Subtitle display ──
              if (!widget.isLive &&
                  _activeSub != null &&
                  _activeSub!.text.isNotEmpty)
                Positioned(
                  bottom: bottomOffset + 12,
                  left: 40,
                  right: 40,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      _activeSub!.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _subFontSize,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Episodes drawer ──
              if (_showControls && _showEpisodes && hasEps)
                _buildEpisodesDrawer(),

              // ── Scrubbing popup ──
              if (_isScrubbing) _buildScrubbingOverlay(),

              // ── Quality picker ──
              if (_showQuality) _buildQualityOverlay(),
            ]),
          ),
        ),
      ),
    );
  }
}
