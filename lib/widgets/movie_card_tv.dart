import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../utils/tv_focus_helper.dart';

class MovieCardTV extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTap;
  final ValueChanged<bool>? onFocus;
  final bool autofocus;

  const MovieCardTV({
    Key? key,
    required this.movie,
    required this.onTap,
    this.onFocus,
    this.autofocus = false,
  }) : super(key: key);

  @override
  _MovieCardTVState createState() => _MovieCardTVState();
}

class _MovieCardTVState extends State<MovieCardTV> {
  final FocusNode _focusNode = TvFocusHelper.createFocusNode(debugLabel: true, debugLabelSuffix: 'movie_card_tv');
  bool _isFocused = false;
  bool _isHovered = false;

  // Design tokens
  static const Color primary = Color(0xFF00E5FF);
  static const Color onSurface = Color(0xFFF0EFFF);
  static const Color onSurfaceVariant = Color(0xFFA59EC6);
  static const Color surfaceContainerHigh = Color(0xFF13112B);

  bool get _isHighlighted => _isFocused || _isHovered;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      widget.onFocus?.call(_isFocused);
    }
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (widget.onFocus != null) {
      widget.onFocus!(hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTV = TvFocusHelper.isTV(context);
    final cardWidth = isTV ? 200.0 : 160.0;
    final cardHeight = isTV ? 300.0 : 240.0;
    final titleSize = TvFocusHelper.getTextSize(context, mobileSize: 14, tvSize: 16);
    final subtitleSize = TvFocusHelper.getTextSize(context, mobileSize: 12, tvSize: 14);
    final spacing = TvFocusHelper.getSpacing(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onFocusChange: _handleFocusChange,
          onKeyEvent: (node, event) => TvFocusHelper.handleKeyEvent(event, widget.onTap),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isHighlighted ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isTV ? 16 : 12),
                      border: Border.all(
                        color: _isHighlighted
                            ? primary.withOpacity(0.8)
                            : Colors.white.withOpacity(0.08),
                        width: _isHighlighted ? 3.0 : 1.0,
                      ),
                      boxShadow: _isHighlighted
                          ? TvFocusHelper.getFocusShadow(context, primary)
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isTV ? 14 : 10),
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
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white38,
                                size: isTV ? 48 : 40,
                              ),
                            ),
                          ),

                          // Hover/Focus overlay with play button
                          AnimatedOpacity(
                            opacity: _isHighlighted ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              color: Colors.black.withOpacity(0.4),
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: isTV ? 64 : 52,
                              ),
                            ),
                          ),

                          // HD Badge (top right)
                          Positioned(
                            top: isTV ? 12 : 8,
                            left: isTV ? 12 : 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTV ? 8 : 6,
                                vertical: isTV ? 3 : 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(isTV ? 6 : 4),
                              ),
                              child: Text(
                                'HD',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: isTV ? 12 : 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // Title
                  SizedBox(
                    width: cardWidth,
                    child: Text(
                      widget.movie.title,
                      style: TextStyle(
                        color: _isHighlighted ? primary : onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Genre / Type subtitle
                  SizedBox(
                    width: cardWidth,
                    child: Text(
                      widget.movie.genres?.isNotEmpty == true
                          ? widget.movie.genres!.take(2).join(' • ')
                          : 'فيلم',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: subtitleSize,
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
