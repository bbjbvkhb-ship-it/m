import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/new_episode_checker_service.dart';

class NewEpisodeModal extends StatelessWidget {
  final List<NewEpisodeResult> results;
  final VoidCallback? onWatch;

  const NewEpisodeModal({
    Key? key,
    required this.results,
    this.onWatch,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    List<NewEpisodeResult> results, {
    VoidCallback? onWatch,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => NewEpisodeModal(results: results, onWatch: onWatch),
    );
  }

  @override
  Widget build(BuildContext context) {
    // إذا كانت هناك نتيجة واحدة فقط، نعرض مودل مفرد
    // وإلا نعرض قائمة
    if (results.length == 1) {
      return _SingleEpisodeDialog(result: results.first, onWatch: onWatch);
    }
    return _MultiEpisodeDialog(results: results, onWatch: onWatch);
  }
}

// ─────────────────────────────────────────────────────────────
// مودل حلقة واحدة (سينمائي/بالبوستر كاملاً)
// ─────────────────────────────────────────────────────────────
class _SingleEpisodeDialog extends StatelessWidget {
  final NewEpisodeResult result;
  final VoidCallback? onWatch;

  const _SingleEpisodeDialog({required this.result, this.onWatch});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const bg = Color(0xFF070514);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── خلفية البوستر الضبابية ──
            if (result.series.posterUrl.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: result.series.posterUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: bg),
                ),
              ),

            // ── طبقة التعتيم ──
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bg.withValues(alpha: 0.55),
                        bg.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── المحتوى ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة التنبيه
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.15),
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: const Icon(Icons.new_releases_rounded,
                        color: accent, size: 30),
                  ),
                  const SizedBox(height: 16),

                  // بادج "حلقة جديدة"
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'حلقة جديدة 🎬',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // اسم المسلسل
                  Text(
                    result.series.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // رقم الحلقة
                  Text(
                    'تم إصدار الحلقة ${result.newEpisodeNumber}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // أزرار
                  Row(
                    children: [
                      // زر مشاهدة
                      Expanded(
                        flex: 2,
                        child: _GlassButton(
                          label: 'شاهد الآن',
                          icon: Icons.play_arrow_rounded,
                          isPrimary: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            onWatch?.call();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // زر لاحقاً
                      Expanded(
                        child: _GlassButton(
                          label: 'لاحقاً',
                          icon: Icons.close_rounded,
                          isPrimary: false,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// مودل حلقات متعددة (قائمة)
// ─────────────────────────────────────────────────────────────
class _MultiEpisodeDialog extends StatelessWidget {
  final List<NewEpisodeResult> results;
  final VoidCallback? onWatch;

  const _MultiEpisodeDialog({required this.results, this.onWatch});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const bg = Color(0xFF070514);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF2E265C).withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // عنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.new_releases_rounded,
                        color: accent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'حلقات جديدة (${results.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // قائمة المسلسلات
                ...results.map((r) => _SeriesRow(result: r)),
                const SizedBox(height: 20),

                // زر إغلاق
                SizedBox(
                  width: double.infinity,
                  child: _GlassButton(
                    label: 'حسناً',
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  final NewEpisodeResult result;
  const _SeriesRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // بوستر مصغر
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: result.series.posterUrl,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 50, height: 70,
                color: const Color(0xFF13112B),
                child: const Icon(Icons.tv_rounded,
                    color: Color(0xFF00E5FF), size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.series.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'الحلقة ${result.newEpisodeNumber} متاحة الآن',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// زر زجاجي مشترك
// ─────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF00B8CC), accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isPrimary ? Colors.black : Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
