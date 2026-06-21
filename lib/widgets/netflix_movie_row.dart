
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/netflix_theme.dart';
import '../models/movie.dart';
import '../screens/netflix_details_screen.dart';

/// صف أفلام بتصميم Netflix
class NetflixMovieRow extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final bool isTV;

  const NetflixMovieRow({
    Key? key,
    required this.title,
    required this.movies,
    required this.isTV,
  }) : super(key: key);

  @override
  _NetflixMovieRowState createState() => _NetflixMovieRowState();
}

class _NetflixMovieRowState extends State<NetflixMovieRow> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _rowFocusNode = FocusNode();
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _rowFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  void _onMovieFocus(int index) {
    setState(() {
      _focusedIndex = index;
    });

    // التمرير التلقائي للعنصر المركز
    if (widget.isTV) {
      final cardWidth = widget.isTV ? 200.0 : 160.0;
      final spacing = widget.isTV ? 16.0 : 8.0;
      final scrollPosition = (index * (cardWidth + spacing)) - 
                           (MediaQuery.of(context).size.width / 2) + 
                           (cardWidth / 2);

      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.isTV ? 300.0 : 240.0;
    final spacing = widget.isTV ? 16.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الصف
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTV ? 80 : 20,
            vertical: widget.isTV ? 24 : 16,
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              color: NetflixTheme.netflixWhite,
              fontSize: widget.isTV ? 24 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'NetflixSans',
            ),
          ),
        ),

        // صف الأفلام
        SizedBox(
          height: cardHeight + (widget.isTV ? 40 : 20),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isTV ? 80 : 20,
            ),
            itemCount: widget.movies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == widget.movies.length - 1 ? 0 : spacing,
                ),
                child: NetflixMovieCard(
                  movie: widget.movies[index],
                  isTV: widget.isTV,
                  isFocused: _focusedIndex == index,
                  onFocus: () => _onMovieFocus(index),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NetflixDetailsScreen(movie: widget.movies[index]),
                    ));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// بطاقة فيلم بتصميم Netflix
class NetflixMovieCard extends StatefulWidget {
  final Movie movie;
  final bool isTV;
  final bool isFocused;
  final VoidCallback onFocus;
  final VoidCallback onTap;

  const NetflixMovieCard({
    Key? key,
    required this.movie,
    required this.isTV,
    required this.isFocused,
    required this.onFocus,
    required this.onTap,
  }) : super(key: key);

  @override
  _NetflixMovieCardState createState() => _NetflixMovieCardState();
}

class _NetflixMovieCardState extends State<NetflixMovieCard> {
  final FocusNode _focusNode = FocusNode();

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
    if (_focusNode.hasFocus) {
      widget.onFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.isTV ? 200.0 : 160.0;
    final cardHeight = widget.isTV ? 300.0 : 240.0;

    return Focus(
      focusNode: _focusNode,
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
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: hasFocus ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasFocus 
                        ? NetflixTheme.netflixWhite 
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: NetflixTheme.netflixWhite.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // صورة الفيلم
                      Image.network(
                        widget.movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: NetflixTheme.netflixDark,
                            child: const Icon(
                              Icons.movie,
                              color: NetflixTheme.netflixLightGray,
                              size: 48,
                            ),
                          );
                        },
                      ),

                      // تدرج لوني في الأسفل
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: cardHeight * 0.4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // عنوان الفيلم
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          widget.movie.title,
                          style: TextStyle(
                            color: NetflixTheme.netflixWhite,
                            fontSize: widget.isTV ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NetflixSans',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // زر التشغيل
                      if (hasFocus)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NetflixTheme.netflixRed,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: NetflixTheme.netflixWhite,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
