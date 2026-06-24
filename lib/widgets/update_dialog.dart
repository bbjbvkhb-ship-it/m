import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
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
        return _UpdateDialogContent(updateInfo: updateInfo);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _UpdateDialogContent(updateInfo: updateInfo);
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final UpdateInfo updateInfo;

  const _UpdateDialogContent({Key? key, required this.updateInfo}) : super(key: key);

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool _isDownloading = false;
  double _progress = 0.0; // from 0.0 to 1.0
  String _statusText = '';

  Future<void> _startDownloadAndInstall(BuildContext context) async {
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final String urlString = isAndroid ? widget.updateInfo.apkUrl : widget.updateInfo.ipaUrl;
    final String fallbackUrl = urlString.isNotEmpty ? urlString : (widget.updateInfo.apkUrl.isNotEmpty ? widget.updateInfo.apkUrl : widget.updateInfo.ipaUrl);

    if (fallbackUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رابط التحديث غير متوفر', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!isAndroid) {
      // Fallback for iOS: launch in browser
      final Uri url = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Android: Download APK locally and install it
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'جاري الاتصال بالسيرفر...';
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(fallbackUrl));
      final response = await client.send(request).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;

      final directory = await getTemporaryDirectory();
      final String apkPath = '${directory.path}/app-update.apk';
      final file = File(apkPath);

      if (await file.exists()) {
        await file.delete();
      }

      final iosink = file.openWrite();
      int downloaded = 0;

      await for (var chunk in response.stream) {
        iosink.add(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          setState(() {
            _progress = downloaded / contentLength;
            _statusText = 'جاري تنزيل التحديث... (${(_progress * 100).toStringAsFixed(0)}%)';
          });
        } else {
          setState(() {
            _statusText = 'جاري تنزيل التحديث... (${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB)';
          });
        }
      }

      await iosink.close();
      client.close();

      setState(() {
        _statusText = 'جاري فتح مثبت الحزم...';
        _progress = 1.0;
      });

      // Trigger Android installer
      final result = await OpenFilex.open(apkPath);
      debugPrint('OpenFilex result: ${result.message}');

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل التحديث: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
          ),
        );
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
                    child: Icon(
                      _isDownloading ? Icons.download_rounded : Icons.system_update_rounded,
                      color: primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _isDownloading ? 'تحميل التحديث الجديد' : 'تحديث جديد متوفر!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Version tag
                  Text(
                    'الإصدار الجديد: ${widget.updateInfo.version}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isDownloading) ...[
                    // Progress UI
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress > 0.0 ? _progress : null,
                        color: primary,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        minHeight: 8,
                      ),
                    ),
                  ] else ...[
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
                          widget.updateInfo.changelog.isNotEmpty
                              ? widget.updateInfo.changelog
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
                            onPressed: () => _startDownloadAndInstall(context),
                          ),
                        ),
                      ],
                    ),
                  ],
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
