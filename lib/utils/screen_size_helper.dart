import 'package:flutter/material.dart';

/// فئة مساعدة لإدارة أحجام الشاشات المختلفة
class ScreenSizeHelper {
  /// الحصول على نوع الشاشة الحالية
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (width >= 1920 || height >= 1080) {
      return ScreenType.largeTV;
    } else if (width >= 1280 || height >= 720) {
      return ScreenType.mediumTV;
    } else if (width >= 768) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  /// التحقق مما إذا كان الجهاز شاشة ذكية
  static bool isTV(BuildContext context) {
    final screenType = getScreenType(context);
    return screenType == ScreenType.largeTV || screenType == ScreenType.mediumTV;
  }

  /// التحقق مما إذا كان الجهاز جهاز لوحي
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  /// الحصول على عامل التكبير المناسب للشاشة
  static double getScaleFactor(BuildContext context) {
    switch (getScreenType(context)) {
      case ScreenType.largeTV:
        return 1.5;
      case ScreenType.mediumTV:
        return 1.3;
      case ScreenType.tablet:
        return 1.1;
      case ScreenType.mobile:
        return 1.0;
    }
  }

  /// حساب حجم بناءً على نوع الشاشة
  static double getScaledSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  /// حساب المسافة المناسبة بناءً على نوع الشاشة
  static double getScaledSpacing(BuildContext context, double baseSpacing) {
    return baseSpacing * getScaleFactor(context);
  }

  /// حساب حجم النص المناسب بناءً على نوع الشاشة
  static double getScaledTextSize(BuildContext context, double baseTextSize) {
    return baseTextSize * getScaleFactor(context);
  }

  /// الحصول على حجم البطاقة المناسب للشاشة
  static Size getCardSize(BuildContext context) {
    final scaleFactor = getScaleFactor(context);
    return Size(160 * scaleFactor, 240 * scaleFactor);
  }

  /// الحصول على حجم الأيقونة المناسب للشاشة
  static double getIconSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  /// الحصول على حجم الزر المناسب للشاشة
  static double getButtonSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  /// الحصول على عرض الشاشة الآمن
  static double getSafeWidth(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return MediaQuery.of(context).size.width - padding.left - padding.right;
  }

  /// الحصول على ارتفاع الشاشة الآمن
  static double getSafeHeight(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return MediaQuery.of(context).size.height - padding.top - padding.bottom;
  }

  /// الحصول على عدد الأعمدة المناسب للشاشة
  static int getColumnCount(BuildContext context, {double itemWidth = 160}) {
    final safeWidth = getSafeWidth(context);
    final scaleFactor = getScaleFactor(context);
    final scaledItemWidth = itemWidth * scaleFactor;
    return (safeWidth / (scaledItemWidth + 16)).floor();
  }
}

/// أنواع الشاشات المدعومة
enum ScreenType {
  mobile,
  tablet,
  mediumTV,
  largeTV,
}
