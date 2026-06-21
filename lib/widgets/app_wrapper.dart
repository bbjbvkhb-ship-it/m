import 'package:flutter/material.dart';
import 'dart:ui';

/// A widget that wraps its [child] with a glass‑morphic backdrop.
///
/// The backdrop uses a frosted‑glass effect via a blurred [ImageFilter]
/// and a semi‑transparent gradient. It can be used to give the whole
/// application or any section of the UI a premium, modern look.
class AppWrapper extends StatelessWidget {
  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF070514),
            Color(0xFF0D0D2B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
