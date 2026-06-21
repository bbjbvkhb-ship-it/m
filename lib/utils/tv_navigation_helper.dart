import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// فئة مساعدة لإدارة التنقل بين العناصر في الشاشات الذكية
class TvNavigationHelper {
  /// إنشاء FocusScopeNode لإدارة مجموعة من العناصر القابلة للتركيز
  static FocusScopeNode createScopeNode({String? debugLabel}) {
    return FocusScopeNode(debugLabel: debugLabel ?? 'tv_navigation_scope');
  }

  /// إنشاء مجموعة تنقل مع ترتيب محدد
  static Widget createTraversalGroup({
    required Widget child,
    String? debugLabel,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }

  /// تغليف عنصر بترتيب تنقل محدد
  static Widget withTraversalOrder({
    required Widget child,
    required int order,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order.toDouble()),
      child: child,
    );
  }

  /// إنشاء قائمة أفقية مع دعم التنقل السلس
  static Widget createHorizontalList({
    required List<Widget> children,
    double spacing = 8.0,
    bool isTV = true,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: isTV ? const AlwaysScrollableScrollPhysics() : null,
      child: Row(
        children: List.generate(
          children.length * 2 - 1,
          (index) {
            if (index.isEven) {
              return children[index ~/ 2];
            } else {
              return SizedBox(width: spacing);
            }
          },
        ),
      ),
    );
  }

  /// إنشاء قائمة عمودية مع دعم التنقل السلس
  static Widget createVerticalList({
    required List<Widget> children,
    double spacing = 8.0,
    bool isTV = true,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: isTV ? const AlwaysScrollableScrollPhysics() : null,
      child: Column(
        children: List.generate(
          children.length * 2 - 1,
          (index) {
            if (index.isEven) {
              return children[index ~/ 2];
            } else {
              return SizedBox(height: spacing);
            }
          },
        ),
      ),
    );
  }

  /// التعامل مع أحداث التنقل في القوائم
  static KeyEventResult handleListNavigation(
    KeyEvent event,
    ScrollController scrollController,
    bool isHorizontal,
  ) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.arrowRight && isHorizontal) {
        scrollController.animateTo(
          scrollController.offset + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowLeft && isHorizontal) {
        scrollController.animateTo(
          scrollController.offset - 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowDown && !isHorizontal) {
        scrollController.animateTo(
          scrollController.offset + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowUp && !isHorizontal) {
        scrollController.animateTo(
          scrollController.offset - 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// إنشاء منطقة قابلة للتركيز مع دعم التنقل
  static Widget createFocusableArea({
    required Widget child,
    FocusNode? focusNode,
    VoidCallback? onTap,
    bool autofocus = false,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: true,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
