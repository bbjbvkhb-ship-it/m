import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_checker_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({Key? key, required this.updateInfo}) : super(key: key);

  static Future<void> show(BuildContext context, UpdateInfo updateInfo) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return UpdateDialog(updateInfo: updateInfo);
      },
    );
  }

  Future<void> _launchUpdate(BuildContext context) async {
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final String urlString = isAndroid ? updateInfo.apkUrl : updateInfo.ipaUrl;
    final String fallbackUrl = urlString.isNotEmpty ? urlString : (updateInfo.apkUrl.isNotEmpty ? updateInfo.apkUrl : updateInfo.ipaUrl);

    if (fallbackUrl.isNotEmpty) {
      final Uri url = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر فتح رابط التحديث تلقائياً', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF13112B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'تحديث جديد متوفر!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Version tag
                  Text(
                    'الإصدار الجديد: ${updateInfo.version}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Changelog title
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'ما الجديد في هذا التحديث:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Changelog body
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        updateInfo.changelog.isNotEmpty
                            ? updateInfo.changelog
                            : 'تحسينات وإصلاحات عامة في أداء التطبيق.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.6,
                          fontFamily: 'Cairo',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Later Button
                      Expanded(
                        child: _FocusableDialogButton(
                          label: 'لاحقاً',
                          isPrimary: false,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Update Button
                      Expanded(
                        child: _FocusableDialogButton(
                          label: 'تحديث الآن',
                          isPrimary: true,
                          autofocus: true,
                          onPressed: () {
                            _launchUpdate(context);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
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

class _FocusableDialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool autofocus;
  final VoidCallback onPressed;

  const _FocusableDialogButton({
    Key? key,
    required this.label,
    required this.isPrimary,
    this.autofocus = false,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<_FocusableDialogButton> createState() => _FocusableDialogButtonState();
}

class _FocusableDialogButtonState extends State<_FocusableDialogButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00E5FF);
    const Color onPrimary = Color(0xFF00373F);

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _focused
                ? primary
                : (widget.isPrimary
                    ? primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? primary : Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: _focused && widget.isPrimary
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _focused
                  ? (widget.isPrimary ? onPrimary : Colors.white)
                  : (widget.isPrimary ? primary : Colors.white70),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}
