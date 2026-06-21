
import 'package:flutter/material.dart';

/// ثيم Netflix المحسن للشاشات الذكية
class NetflixTheme {
  // ألوان Netflix الرئيسية
  static const Color netflixRed = Color(0xFFE50914);
  static const Color netflixBlack = Color(0xFF141414);
  static const Color netflixDark = Color(0xFF181818);
  static const Color netflixGray = Color(0xFF2F2F2F);
  static const Color netflixLightGray = Color(0xFFB3B3B3);
  static const Color netflixWhite = Color(0xFFFFFFFF);

  // ثيم Netflix للشاشات الذكية
  static ThemeData get tvTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: netflixRed,
      scaffoldBackgroundColor: netflixBlack,
      cardColor: netflixDark,

      // ألوان النصوص
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: netflixWhite,
          fontSize: 56,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        displayMedium: TextStyle(
          color: netflixWhite,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        displaySmall: TextStyle(
          color: netflixWhite,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        headlineLarge: TextStyle(
          color: netflixWhite,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        headlineMedium: TextStyle(
          color: netflixWhite,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        headlineSmall: TextStyle(
          color: netflixWhite,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        titleLarge: TextStyle(
          color: netflixWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        titleMedium: TextStyle(
          color: netflixWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        titleSmall: TextStyle(
          color: netflixWhite,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        bodyLarge: TextStyle(
          color: netflixWhite,
          fontSize: 16,
          fontFamily: 'NetflixSans',
        ),
        bodyMedium: TextStyle(
          color: netflixWhite,
          fontSize: 14,
          fontFamily: 'NetflixSans',
        ),
        bodySmall: TextStyle(
          color: netflixLightGray,
          fontSize: 12,
          fontFamily: 'NetflixSans',
        ),
        labelLarge: TextStyle(
          color: netflixWhite,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        labelMedium: TextStyle(
          color: netflixWhite,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        labelSmall: TextStyle(
          color: netflixLightGray,
          fontSize: 10,
          fontFamily: 'NetflixSans',
        ),
      ),

      // ألوان التركيز
      focusColor: netflixRed,
      hoverColor: netflixRed.withOpacity(0.1),

      // ألوان الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: netflixWhite,
          foregroundColor: netflixBlack,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NetflixSans',
          ),
        ),
      ),

      // ألوان البطاقات
      cardTheme: CardThemeData(
        color: netflixDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ألوان القوائم
      listTileTheme: const ListTileThemeData(
        tileColor: netflixDark,
        selectedColor: netflixWhite,
        iconColor: netflixLightGray,
        textColor: netflixWhite,
      ),

      // ألوان الأيقونات
      iconTheme: const IconThemeData(
        color: netflixWhite,
        size: 24,
      ),

      // ألوان شريط التطبيق
      appBarTheme: const AppBarTheme(
        backgroundColor: netflixBlack,
        foregroundColor: netflixWhite,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: netflixWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
      ),

      // ألوان شريط التنقل السفلي
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: netflixBlack,
        selectedItemColor: netflixWhite,
        unselectedItemColor: netflixLightGray,
        type: BottomNavigationBarType.fixed,
      ),

      // ألوان الـ Divider
      dividerTheme: const DividerThemeData(
        color: netflixGray,
        thickness: 1,
      ),

      // ألوان الـ SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: netflixDark,
        contentTextStyle: const TextStyle(
          color: netflixWhite,
          fontFamily: 'NetflixSans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ألوان الـ Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: netflixDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        titleTextStyle: const TextStyle(
          color: netflixWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        contentTextStyle: const TextStyle(
          color: netflixWhite,
          fontSize: 16,
          fontFamily: 'NetflixSans',
        ),
      ),
    );
  }

  // ثيم Netflix للموبايل
  static ThemeData get mobileTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: netflixRed,
      scaffoldBackgroundColor: netflixBlack,
      cardColor: netflixDark,

      // ألوان النصوص
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: netflixWhite,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        displayMedium: TextStyle(
          color: netflixWhite,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        displaySmall: TextStyle(
          color: netflixWhite,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        headlineLarge: TextStyle(
          color: netflixWhite,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        headlineMedium: TextStyle(
          color: netflixWhite,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        headlineSmall: TextStyle(
          color: netflixWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        titleLarge: TextStyle(
          color: netflixWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        titleMedium: TextStyle(
          color: netflixWhite,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        titleSmall: TextStyle(
          color: netflixWhite,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        bodyLarge: TextStyle(
          color: netflixWhite,
          fontSize: 14,
          fontFamily: 'NetflixSans',
        ),
        bodyMedium: TextStyle(
          color: netflixWhite,
          fontSize: 12,
          fontFamily: 'NetflixSans',
        ),
        bodySmall: TextStyle(
          color: netflixLightGray,
          fontSize: 10,
          fontFamily: 'NetflixSans',
        ),
        labelLarge: TextStyle(
          color: netflixWhite,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        labelMedium: TextStyle(
          color: netflixWhite,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        labelSmall: TextStyle(
          color: netflixLightGray,
          fontSize: 8,
          fontFamily: 'NetflixSans',
        ),
      ),

      // ألوان التركيز
      focusColor: netflixRed,
      hoverColor: netflixRed.withOpacity(0.1),

      // ألوان الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: netflixWhite,
          foregroundColor: netflixBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'NetflixSans',
          ),
        ),
      ),

      // ألوان البطاقات
      cardTheme: CardThemeData(
        color: netflixDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ألوان القوائم
      listTileTheme: const ListTileThemeData(
        tileColor: netflixDark,
        selectedColor: netflixWhite,
        iconColor: netflixLightGray,
        textColor: netflixWhite,
      ),

      // ألوان الأيقونات
      iconTheme: const IconThemeData(
        color: netflixWhite,
        size: 20,
      ),

      // ألوان شريط التطبيق
      appBarTheme: const AppBarTheme(
        backgroundColor: netflixBlack,
        foregroundColor: netflixWhite,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: netflixWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
      ),

      // ألوان شريط التنقل السفلي
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: netflixBlack,
        selectedItemColor: netflixWhite,
        unselectedItemColor: netflixLightGray,
        type: BottomNavigationBarType.fixed,
      ),

      // ألوان الـ Divider
      dividerTheme: const DividerThemeData(
        color: netflixGray,
        thickness: 1,
      ),

      // ألوان الـ SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: netflixDark,
        contentTextStyle: const TextStyle(
          color: netflixWhite,
          fontFamily: 'NetflixSans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ألوان الـ Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: netflixDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        titleTextStyle: const TextStyle(
          color: netflixWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'NetflixSans',
        ),
        contentTextStyle: const TextStyle(
          color: netflixWhite,
          fontSize: 14,
          fontFamily: 'NetflixSans',
        ),
      ),
    );
  }

  // الحصول على الثيم المناسب حسب نوع الجهاز
  static ThemeData getTheme(BuildContext context) {
    return MediaQuery.of(context).size.width > 700 ? tvTheme : mobileTheme;
  }
}
