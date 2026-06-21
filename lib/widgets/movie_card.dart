import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTap;
  final ValueChanged<bool>? onFocus;

  const MovieCard({super.key, required this.movie, required this.onTap, this.onFocus});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  // Design tokens from _2/code.html Tailwind config
  static const Color primary = Color(0xFF00E5FF);
  static const Color onSurface = Color(0xFFF0EFFF);
  static const Color onSurfaceVariant = Color(0xFFA59EC6);
  static const Color surfaceContainerHigh = Color(0xFF13112B);

  bool get _isHighlighted => _isFocused || _isHovered;

  void _handleFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (widget.onFocus != null) {
      widget.onFocus!(hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Focus(
          onFocusChange: _handleFocusChange,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.enter || 
                  key == LogicalKeyboardKey.select || 
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
            child: AnimatedScale(
              scale: _isHighlighted ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 260,
                    height: 146,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: _isHighlighted
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white.withValues(alpha: 0.0), width: 2),
                      boxShadow: _isHighlighted
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Poster Image
                          CachedNetworkImage(
                            imageUrl: widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: surfaceContainerHigh,
                              child: const Center(
                                child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: surfaceContainerHigh,
                              child: const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 40),
                            ),
                          ),

                          // Hover/Focus overlay with play button
                          AnimatedOpacity(
                            opacity: _isHighlighted ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                            ),
                          ),

                          // Mockup HD Badge (top right)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HD',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          // Mockup Top 10 Badge
                          if (widget.movie.title.length > 10) 
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE50914),
                                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('TOP', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    Text('10', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  SizedBox(
                    width: 260,
                    child: Text(
                      widget.movie.title,
                      style: TextStyle(
                        color: _isHighlighted ? Colors.white : onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Genre / Type subtitle
                  SizedBox(
                    width: 260,
                    child: const Text(
                      'حلقات متوفرة مجاناً',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
