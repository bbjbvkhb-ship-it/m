import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// فئة مساعدة للتعامل مع أحداث الريموت
class TvRemoteHelper {
  /// التعامل مع أحداث الريموت الرئيسية
  static KeyEventResult handleRemoteEvent(
    KeyEvent event,
    {
    VoidCallback? onEnter,
    VoidCallback? onBack,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onPlayPause,
    VoidCallback? onMute,
    VoidCallback? onVolumeUp,
    VoidCallback? onVolumeDown,
    VoidCallback? onChannelUp,
    VoidCallback? onChannelDown,
  }) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // أزرار التنقل الرئيسية
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space) {
        onEnter?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.backspace) {
        onBack?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowUp) {
        onUp?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowDown) {
        onDown?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowLeft) {
        onLeft?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowRight) {
        onRight?.call();
        return KeyEventResult.handled;
      }

      // أزرار التحكم في الوسائط
      if (key == LogicalKeyboardKey.mediaPlayPause) {
        onPlayPause?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.audioVolumeMute) {
        onMute?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.audioVolumeUp) {
        onVolumeUp?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.audioVolumeDown) {
        onVolumeDown?.call();
        return KeyEventResult.handled;
      }

      // أزرار القنوات
      if (key == LogicalKeyboardKey.channelUp) {
        onChannelUp?.call();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.channelDown) {
        onChannelDown?.call();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// إنشاء مستمع لأحداث الريموت
  static Widget createRemoteListener({
    required Widget child,
    VoidCallback? onEnter,
    VoidCallback? onBack,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onPlayPause,
    VoidCallback? onMute,
    VoidCallback? onVolumeUp,
    VoidCallback? onVolumeDown,
    VoidCallback? onChannelUp,
    VoidCallback? onChannelDown,
    FocusNode? focusNode,
    bool autofocus = true,
  }) {
    return KeyboardListener(
      focusNode: focusNode ?? FocusNode(),
      autofocus: autofocus,
      onKeyEvent: (event) => handleRemoteEvent(
        event,
        onEnter: onEnter,
        onBack: onBack,
        onUp: onUp,
        onDown: onDown,
        onLeft: onLeft,
        onRight: onRight,
        onPlayPause: onPlayPause,
        onMute: onMute,
        onVolumeUp: onVolumeUp,
        onVolumeDown: onVolumeDown,
        onChannelUp: onChannelUp,
        onChannelDown: onChannelDown,
      ),
      child: child,
    );
  }

  /// التحقق مما إذا كان المفتاح مفتاح تنقل
  static bool isNavigationKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace;
  }

  /// التحقق مما إذا كان المفتاح مفتاح تحكم في الوسائط
  static bool isMediaKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.audioVolumeMute ||
        key == LogicalKeyboardKey.audioVolumeUp ||
        key == LogicalKeyboardKey.audioVolumeDown ||
        key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.channelDown;
  }

  /// الحصول على اسم المفتاح بالعربية
  static String getKeyNameArabic(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        return 'أعلى';
      case LogicalKeyboardKey.arrowDown:
        return 'أسفل';
      case LogicalKeyboardKey.arrowLeft:
        return 'يسار';
      case LogicalKeyboardKey.arrowRight:
        return 'يمين';
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.numpadEnter:
        return 'موافق';
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.backspace:
        return 'رجوع';
      case LogicalKeyboardKey.mediaPlayPause:
        return 'تشغيل/إيقاف';
      case LogicalKeyboardKey.audioVolumeMute:
        return 'كتم الصوت';
      case LogicalKeyboardKey.audioVolumeUp:
        return 'رفع الصوت';
      case LogicalKeyboardKey.audioVolumeDown:
        return 'خفض الصوت';
      case LogicalKeyboardKey.channelUp:
        return 'القناة التالية';
      case LogicalKeyboardKey.channelDown:
        return 'القناة السابقة';
      default:
        return '';
    }
  }

  /// إنشاء رسالة تعليمية للمستخدم
  static String getInstructionMessage(String action) {
    return 'استخدم أزرار الريموت للتنقل. اضغط على زر "موافق" لـ $action';
  }
}
