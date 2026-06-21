import 'dart:math' as math;
import 'package:flutter/material.dart';

enum LogoStyle { glassOrb, goldenLuxury, cyberpunk }

class LogoManager extends ChangeNotifier {
  static final LogoManager instance = LogoManager._internal();
  LogoManager._internal();

  LogoStyle _currentStyle = LogoStyle.glassOrb;

  LogoStyle get currentStyle => _currentStyle;

  void setStyle(LogoStyle style) {
    _currentStyle = style;
    notifyListeners();
  }
}

/// A wrapper widget that automatically renders the currently selected logo style
class TvPlusLiveLogo extends StatelessWidget {
  final double size;
  const TvPlusLiveLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LogoManager.instance,
      builder: (context, _) {
        switch (LogoManager.instance.currentStyle) {
          case LogoStyle.glassOrb:
            return TvPlusLogoStyleGlassOrb(size: size);
          case LogoStyle.goldenLuxury:
            return TvPlusLogoStyleGoldenLuxury(size: size);
          case LogoStyle.cyberpunk:
            return TvPlusLogoStyleCyberpunk(size: size);
        }
      },
    );
  }
}

// ==========================================
// 1. STYLE: GLASS ORB (أورب زجاجي متوهج)
// ==========================================
class TvPlusLogoStyleGlassOrb extends StatefulWidget {
  final double size;
  const TvPlusLogoStyleGlassOrb({super.key, required this.size});

  @override
  State<TvPlusLogoStyleGlassOrb> createState() => _TvPlusLogoStyleGlassOrbState();
}

class _TvPlusLogoStyleGlassOrbState extends State<TvPlusLogoStyleGlassOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GlassOrbPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

class _GlassOrbPainter extends CustomPainter {
  final double animationValue;
  _GlassOrbPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Neon Outer Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFBD00FF).withValues(alpha: 0.4),
          const Color(0xFF00E5FF).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.5, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // 2. Base Dark Sphere
    final spherePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF03020A),
          const Color(0xFF130F30),
          const Color(0xFF03020A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.95, spherePaint);

    // 3. Glowing Golden Light Arc (Orbits)
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFFD700).withValues(alpha: 0.8),
          const Color(0xFF00E5FF),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.75, 1.0],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.9))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      0,
      2 * math.pi,
      false,
      arcPaint,
    );

    // 4. Glossy Highlight Reflection (Top glass cap)
    final glassPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final glassPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(center.dx, center.dy - radius * 0.1), radius: radius * 0.85),
        math.pi,
        math.pi,
      )
      ..close();

    canvas.drawPath(glassPath, glassPaint);

    // 5. Drawing text "TV+" inside the orb
    const textSpan = TextSpan(
      text: 'TV',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 18,
        fontFamily: 'Cairo',
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Color(0xFF00E5FF),
            blurRadius: 8,
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2 - 3,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Dynamic Golden glowing '+' symbol
    const plusSpan = TextSpan(
      text: '+',
      style: TextStyle(
        color: Color(0xFFFFD700),
        fontWeight: FontWeight.w900,
        fontSize: 22,
        fontFamily: 'Cairo',
        shadows: [
          Shadow(
            color: Color(0xFFFFD700),
            blurRadius: 10,
          ),
        ],
      ),
    );
    final plusPainter = TextPainter(
      text: plusSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final plusOffset = Offset(
      center.dx + textPainter.width / 2 - 2,
      center.dy - plusPainter.height / 2 - 3,
    );
    plusPainter.paint(canvas, plusOffset);
  }

  @override
  bool shouldRepaint(covariant _GlassOrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ==========================================
// 2. STYLE: GOLDEN LUXURY (الذهبي الملكي الهادئ)
// ==========================================
class TvPlusLogoStyleGoldenLuxury extends StatefulWidget {
  final double size;
  const TvPlusLogoStyleGoldenLuxury({super.key, required this.size});

  @override
  State<TvPlusLogoStyleGoldenLuxury> createState() => _TvPlusLogoStyleGoldenLuxuryState();
}

class _TvPlusLogoStyleGoldenLuxuryState extends State<TvPlusLogoStyleGoldenLuxury>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GoldenLuxuryPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

class _GoldenLuxuryPainter extends CustomPainter {
  final double animationValue;
  _GoldenLuxuryPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Luxury Gold Outer Ring
    final goldRingPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF8A6421),
          Color(0xFFD4AF37),
          Color(0xFFF3E5AB),
          Color(0xFFD4AF37),
          Color(0xFF8A6421),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius * 0.9, goldRingPaint);

    // Subtle internal golden glow
    final softGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.95))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius * 0.8, softGlowPaint);

    // 2. Matte Black Velvet Plate
    final darkPlatePaint = Paint()
      ..color = const Color(0xFF12121A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.84, darkPlatePaint);

    // 3. Luxurious Gold Typography
    final textSpan = TextSpan(
      text: 'TV',
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 17,
        fontWeight: FontWeight.w900,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFF3E5AB),
              Color(0xFFD4AF37),
              Color(0xFF8A6421),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTRB(0, 0, size.width, size.height)),
        shadows: const [
          Shadow(
            color: Colors.black,
            blurRadius: 5,
            offset: Offset(1, 2),
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2 - 3,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Red luxury accent '+' sign
    const plusSpan = TextSpan(
      text: '+',
      style: TextStyle(
        color: Color(0xFFFF2D55),
        fontWeight: FontWeight.w900,
        fontSize: 21,
        fontFamily: 'Cairo',
        shadows: [
          Shadow(
            color: Color(0xFFFF2D55),
            blurRadius: 8,
          ),
        ],
      ),
    );
    final plusPainter = TextPainter(
      text: plusSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final plusOffset = Offset(
      center.dx + textPainter.width / 2 - 1,
      center.dy - plusPainter.height / 2 - 2,
    );
    plusPainter.paint(canvas, plusOffset);
  }

  @override
  bool shouldRepaint(covariant _GoldenLuxuryPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ==========================================
// 3. STYLE: CYBERPUNK (سايبر بانك ثلاثي الأبعاد)
// ==========================================
class TvPlusLogoStyleCyberpunk extends StatefulWidget {
  final double size;
  const TvPlusLogoStyleCyberpunk({super.key, required this.size});

  @override
  State<TvPlusLogoStyleCyberpunk> createState() => _TvPlusLogoStyleCyberpunkState();
}

class _TvPlusLogoStyleCyberpunkState extends State<TvPlusLogoStyleCyberpunk>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CyberpunkPainter(pulseValue: _controller.value),
        );
      },
    );
  }
}

class _CyberpunkPainter extends CustomPainter {
  final double pulseValue;
  _CyberpunkPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Double Glowing Neon Circles
    // Neon Cyber-Cyan Circle
    final cyanRingPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5 + 0.5 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * pulseValue);
    canvas.drawCircle(center, radius * 0.9, cyanRingPaint);

    // Neon Cyber-Magenta Circle
    final magentaRingPaint = Paint()
      ..color = const Color(0xFFBD00FF).withValues(alpha: 0.4 + 0.6 * (1 - pulseValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * (1 - pulseValue));
    canvas.drawCircle(center, radius * 0.82, magentaRingPaint);

    // Tech Grid Background Detail
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius * 0.7, center.dy), Offset(center.dx + radius * 0.7, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius * 0.7), Offset(center.dx, center.dy + radius * 0.7), gridPaint);

    // Cyberpunk dynamic high-contrast typography
    final textSpan = TextSpan(
      text: 'TV',
      style: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w900,
        fontSize: 17,
        fontFamily: 'Cairo',
        shadows: [
          Shadow(
            color: const Color(0xFF00E5FF),
            blurRadius: 5 + 5 * pulseValue,
            offset: const Offset(-1, -1),
          ),
          Shadow(
            color: const Color(0xFFBD00FF),
            blurRadius: 5 + 5 * (1 - pulseValue),
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2 - 3,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Neon magenta '+' sign
    final plusSpan = TextSpan(
      text: '+',
      style: TextStyle(
        color: const Color(0xFFBD00FF),
        fontWeight: FontWeight.w900,
        fontSize: 22,
        fontFamily: 'Cairo',
        shadows: [
          Shadow(
            color: const Color(0xFFBD00FF),
            blurRadius: 10 + 10 * pulseValue,
          ),
          const Shadow(
            color: Color(0xFF00E5FF),
            blurRadius: 5,
          ),
        ],
      ),
    );
    final plusPainter = TextPainter(
      text: plusSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final plusOffset = Offset(
      center.dx + textPainter.width / 2 - 1,
      center.dy - plusPainter.height / 2 - 3,
    );
    plusPainter.paint(canvas, plusOffset);
  }

  @override
  bool shouldRepaint(covariant _CyberpunkPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

// ==========================================
// 4. DIALOG / MODAL FOR LOGO SHOWCASE
// ==========================================
void showLogoSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF0D0A21),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2E265C), width: 1.5),
        ),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dialog Header
              const Text(
                'اختر شعار التطبيق المفضل لديك 🎨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'اضغط على الشعار الذي تراه أنسب للتطبيق وسيتم اعتماده وتحديثه في كامل النظام والواجهات فوراً!',
                style: TextStyle(
                  color: Color(0xFFA59EC6),
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Showcase row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LogoOptionCard(
                    style: LogoStyle.glassOrb,
                    title: 'الزجاجي الحديث',
                    widget: const TvPlusLogoStyleGlassOrb(size: 80),
                  ),
                  _LogoOptionCard(
                    style: LogoStyle.goldenLuxury,
                    title: 'الذهبي الملكي',
                    widget: const TvPlusLogoStyleGoldenLuxury(size: 80),
                  ),
                  _LogoOptionCard(
                    style: LogoStyle.cyberpunk,
                    title: 'سايبر بانك',
                    widget: const TvPlusLogoStyleCyberpunk(size: 80),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Close Button
              SizedBox(
                width: 160,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                    ),
                  ),
                  child: const Text(
                    'تم الاختيار',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LogoOptionCard extends StatelessWidget {
  final LogoStyle style;
  final String title;
  final Widget widget;

  const _LogoOptionCard({
    required this.style,
    required this.title,
    required this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LogoManager.instance,
      builder: (context, _) {
        final isSelected = LogoManager.instance.currentStyle == style;

        return Focus(
          child: Builder(
            builder: (context) {
              final hasFocus = Focus.of(context).hasFocus;

              return AnimatedScale(
                scale: hasFocus ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: InkWell(
                  onTap: () {
                    LogoManager.instance.setStyle(style);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                          : hasFocus
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : hasFocus
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                blurRadius: 15,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget,
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
