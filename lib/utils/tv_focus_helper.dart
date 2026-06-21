
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// فئة مساعدة لتحسين دعم التركيز على الشاشات الذكية
class TvFocusHelper {
  /// إنشاء FocusNode مع إعدادات محسنة للشاشات الذكية
  static FocusNode createFocusNode({
    bool debugLabel = false,
    String? debugLabelSuffix,
  }) {
    return FocusNode(
      debugLabel: debugLabel ? 'tv_focus_${debugLabelSuffix ?? 'node'}' : null,
    );
  }

  /// التحقق مما إذا كان الجهاز شاشة ذكية
  static bool isTV(BuildContext context) {
    return MediaQuery.of(context).size.width > 700;
  }

  /// الحصول على حجم مناسب للعناصر التفاعلية بناءً على نوع الجهاز
  static double getInteractiveSize(BuildContext context, {double mobileSize = 48, double tvSize = 64}) {
    return isTV(context) ? tvSize : mobileSize;
  }

  /// الحصول على حجم مناسب للنصوص بناءً على نوع الجهاز
  static double getTextSize(BuildContext context, {double mobileSize = 14, double tvSize = 18}) {
    return isTV(context) ? tvSize : mobileSize;
  }

  /// الحصول على مسافة مناسبة بين العناصر
  static double getSpacing(BuildContext context, {double mobileSpacing = 8, double tvSpacing = 16}) {
    return isTV(context) ? tvSpacing : mobileSpacing;
  }

  /// الحصول على حجم حدود التركيز المناسب
  static double getFocusBorderWidth(BuildContext context) {
    return isTV(context) ? 3.0 : 2.0;
  }

  /// الحصول على تأثير الظل للعنصر المركز
  static List<BoxShadow> getFocusShadow(BuildContext context, Color focusColor) {
    if (!isTV(context)) return [];
    return [
      BoxShadow(
        color: focusColor.withOpacity(0.4),
        blurRadius: 24,
        spreadRadius: 4,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// التعامل مع أحداث لوحة المفاتيح للشاشات الذكية
  static KeyEventResult handleKeyEvent(
    KeyEvent event,
    VoidCallback? onActivate,
  ) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space) {
        onActivate?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// إنشاء حدود التركيز المخصصة
  static BoxDecoration getFocusDecoration({
    required bool isFocused,
    required Color focusColor,
    double? borderWidth,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? focusColor : Colors.white.withOpacity(0.1),
        width: borderWidth ?? (isFocused ? 3.0 : 1.0),
      ),
    );
  }
}

/// ودجت مخصص للتحكم في التركيز على الشاشات الذكية
class TvFocusableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onFocusChange;
  final VoidCallback? onActivate;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool showFocusBorder;
  final Color focusColor;

  const TvFocusableWidget({
    Key? key,
    required this.child,
    this.onFocusChange,
    this.onActivate,
    this.autofocus = false,
    this.focusNode,
    this.showFocusBorder = true,
    this.focusColor = const Color(0xFF00E5FF),
  }) : super(key: key);

  @override
  _TvFocusableWidgetState createState() => _TvFocusableWidgetState();
}

class _TvFocusableWidgetState extends State<TvFocusableWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? TvFocusHelper.createFocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      widget.onFocusChange?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) => TvFocusHelper.handleKeyEvent(
        event,
        widget.onActivate,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: widget.showFocusBorder && _isFocused
            ? BoxDecoration(
                border: Border.all(
                  color: widget.focusColor,
                  width: TvFocusHelper.getFocusBorderWidth(context),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: TvFocusHelper.getFocusShadow(context, widget.focusColor),
              )
            : null,
        child: widget.child,
      ),
    );
  }
}
