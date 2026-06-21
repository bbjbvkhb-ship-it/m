
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// أزرار التحكم في المشغل المخصصة للشاشات الذكية
class TvPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final VoidCallback onSkipIntro;
  final bool showSkipIntro;
  final bool isLive;

  const TvPlayerControls({
    super.key,
    required this.controller,
    required this.onPlayPause,
    required this.onRewind,
    required this.onForward,
    required this.onSkipIntro,
    this.showSkipIntro = false,
    this.isLive = false,
  });

  @override
  State<TvPlayerControls> createState() => _TvPlayerControlsState();
}

class _TvPlayerControlsState extends State<TvPlayerControls> {
  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _rewindFocusNode = FocusNode();
  final FocusNode _forwardFocusNode = FocusNode();
  final FocusNode _skipIntroFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // طلب التركيز التلقائي على زر التشغيل/الإيقاف
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _playPauseFocusNode.canRequestFocus) {
        _playPauseFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _playPauseFocusNode.dispose();
    _rewindFocusNode.dispose();
    _forwardFocusNode.dispose();
    _skipIntroFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 700;
    final buttonSize = isTV ? 72.0 : 56.0;
    final iconSize = isTV ? 36.0 : 28.0;

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      padding: EdgeInsets.symmetric(
        horizontal: isTV ? 48 : 24,
        vertical: isTV ? 32 : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر تخطي المقدمة (يظهر فقط عند الحاجة)
          if (widget.showSkipIntro && !widget.isLive)
            _buildSkipIntroButton(isTV),

          if (widget.showSkipIntro && !widget.isLive)
            SizedBox(height: isTV ? 24 : 16),

          // شريط التقدم (للبث المسجل فقط)
          if (!widget.isLive)
            _buildProgressBar(isTV),

          if (!widget.isLive)
            SizedBox(height: isTV ? 24 : 16),

          // أزرار التحكم الرئيسية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر الترجيع
              _buildControlButton(
                icon: Icons.replay_10_rounded,
                focusNode: _rewindFocusNode,
                onPressed: widget.onRewind,
                size: buttonSize,
                iconSize: iconSize,
                isTV: isTV,
              ),

              SizedBox(width: isTV ? 32 : 16),

              // زر التشغيل/الإيقاف
              _buildControlButton(
                icon: widget.controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                focusNode: _playPauseFocusNode,
                onPressed: widget.onPlayPause,
                size: buttonSize * 1.2,
                iconSize: iconSize * 1.2,
                isTV: isTV,
                isPrimary: true,
              ),

              SizedBox(width: isTV ? 32 : 16),

              // زر التقديم
              _buildControlButton(
                icon: Icons.forward_10_rounded,
                focusNode: _forwardFocusNode,
                onPressed: widget.onForward,
                size: buttonSize,
                iconSize: iconSize,
                isTV: isTV,
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

  Widget _buildSkipIntroButton(bool isTV) {
    return Focus(
      focusNode: _skipIntroFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space) {
            widget.onSkipIntro();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: widget.onSkipIntro,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isTV ? 32 : 24,
                vertical: isTV ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: hasFocus
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTV ? 12 : 8),
                border: Border.all(
                  color: hasFocus ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.3),
                  width: hasFocus ? 3 : 1,
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.skip_next_rounded,
                    color: hasFocus ? const Color(0xFF00E5FF) : Colors.white,
                    size: isTV ? 28 : 24,
                  ),
                  SizedBox(width: isTV ? 12 : 8),
                  Text(
                    'تخطي المقدمة',
                    style: TextStyle(
                      color: hasFocus ? const Color(0xFF00E5FF) : Colors.white,
                      fontSize: isTV ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
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

  Widget _buildControlButton({
    required IconData icon,
    required FocusNode focusNode,
    required VoidCallback onPressed,
    required double size,
    required double iconSize,
    required bool isTV,
    bool isPrimary = false,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space) {
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
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isPrimary
                    ? (hasFocus ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.2))
                    : (hasFocus ? Colors.white.withValues(alpha: 0.2) : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasFocus ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.3),
                  width: hasFocus ? 3 : 2,
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                          blurRadius: isPrimary ? 24 : 16,
                          spreadRadius: isPrimary ? 4 : 2,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? (hasFocus ? Colors.black : Colors.white)
                    : (hasFocus ? const Color(0xFF00E5FF) : Colors.white),
                size: iconSize,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(bool isTV) {
    return VideoProgressIndicator(
      widget.controller,
      allowScrubbing: true,
      colors: const VideoProgressColors(
        playedColor: Color(0xFF00E5FF),
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white12,
      ),
      padding: EdgeInsets.symmetric(horizontal: isTV ? 24 : 16),
    );
  }

  Widget _buildTimeInfo(bool isTV) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDuration(position),
          style: TextStyle(
            color: Colors.white,
            fontSize: isTV ? 16 : 14,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          ' / ',
          style: TextStyle(
            color: Colors.white54,
            fontSize: isTV ? 16 : 14,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          _formatDuration(duration),
          style: TextStyle(
            color: Colors.white54,
            fontSize: isTV ? 16 : 14,
            fontFamily: 'Cairo',
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
