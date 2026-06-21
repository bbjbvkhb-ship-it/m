import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// فئة مساعدة لتحسين أداء التطبيق على الشاشات الذكية
class TvPerformanceHelper {
  /// التحقق مما إذا كان الجهاز يحتاج إلى تحسينات الأداء
  static bool needsPerformanceOptimization(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // الشاشات الكبيرة قد تحتاج إلى تحسينات إضافية
    return width >= 1920 || height >= 1080;
  }

  /// الحصول على عدد العناصر التي يجب تحميلها مسبقاً
  static int getPreloadCount(BuildContext context) {
    if (needsPerformanceOptimization(context)) {
      return 10; // تحميل المزيد من العناصر مسبقاً على الشاشات الكبيرة
    }
    return 5;
  }

  /// الحصول على حجم الذاكرة المؤقتة للصور
  static int getImageCacheSize(BuildContext context) {
    if (needsPerformanceOptimization(context)) {
      return 200; // ذاكرة أكبر للصور على الشاشات الكبيرة
    }
    return 100;
  }

  /// إنشاء مُنشئ للقوائم المحسّنة
  static Widget buildOptimizedListView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemExtent: itemExtent,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      cacheExtent: 500.0,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  /// إنشاء مُنشئ للشبكات المحسّنة
  static Widget buildOptimizedGridView({
    IndexedWidgetBuilder? itemBuilder,
    required SliverChildDelegate delegate,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.custom(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      cacheExtent: 500.0,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      childrenDelegate: delegate,
    );
  }

  /// تأخير التنفيذ الثقيل حتى يصبح الإطار جاهزاً
  static void executeAfterFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// تأخير التنفيذ لفترة قصيرة
  static Future<void> delayExecution(Duration duration, VoidCallback callback) async {
    await Future.delayed(duration);
    callback();
  }

  /// التحقق مما إذا كان التطبيق في الخلفية
  static bool isAppInBackground() {
    return WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
  }

  /// إيقاف التحديثات الثقيلة عندما يكون التطبيق في الخلفية
  static bool shouldUpdateWidget() {
    return !isAppInBackground();
  }

  /// تحسين جودة الصور بناءً على نوع الشاشة
  static int getImageQuality(BuildContext context) {
    if (needsPerformanceOptimization(context)) {
      return 90; // جودة عالية للشاشات الكبيرة
    }
    return 75; // جودة متوسطة للشاشات الصغيرة
  }

  /// الحصول على حجم الصورة المناسب للشاشة
  static int getImageWidth(BuildContext context, double displayWidth) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (displayWidth * pixelRatio).round();
  }

  /// تحسين عدد العناصر المرئية في القائمة
  static int getVisibleItemCount(BuildContext context, double itemHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight / itemHeight).ceil() + 2;
  }
}
