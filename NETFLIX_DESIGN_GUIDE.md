
# دليل تصميم Netflix لتطبيق TV Plus

## نظرة عامة
تم إنشاء تصميم Netflix كامل لتطبيق TV Plus، مع التركيز على توفير تجربة مستخدم مماثلة لـ Netflix على الشاشات الذكية.

## الملفات الجديدة

### 1. lib/theme/netflix_theme.dart
يحتوي على ثيم Netflix الكامل:
- ألوان Netflix الأساسية (الأحمر، الأسود، الرمادي)
- أنماط النصوص
- أنماط الأزرار
- أنماط البطاقات
- أنماط القوائم
- أنماط الأيقونات
- أنماط شريط التطبيق
- أنماط شريط التنقل السفلي
- أنماط الـ SnackBar
- أنماط الـ Dialog

### 2. lib/screens/netflix_home_screen.dart
الشاشة الرئيسية بتصميم Netflix:
- شريط Netflix العلوي مع الشعار
- قسم Hero مع فيلم مميز
- صفوف الأفلام الأفقية
- أزرار التشغيل والمعلومات
- دعم كامل للتنقل بلوحة التحكم

### 3. lib/widgets/netflix_movie_row.dart
صفوف الأفلام بتصميم Netflix:
- بطاقات أفلام بتصميم Netflix
- تمرير أفقي سلس
- تأثيرات التركيز
- زر التشغيل عند التركيز
- تدرج لوني في الأسفل

### 4. lib/screens/netflix_details_screen.dart
شاشة التفاصيل بتصميم Netflix:
- شريط علوي متحرك
- قسم Hero مع صورة كبيرة
- معلومات الفيلم
- أزرار التشغيل والمعلومات
- طاقم العمل
- دعم كامل للتنقل بلوحة التحكم

### 5. lib/screens/netflix_player_screen.dart
شاشة المشغل بتصميم Netflix:
- مشغل فيديو بتصميم Netflix
- أزرار تحكم كبيرة وواضحة
- شريط تقدم
- معلومات الوقت
- دعم كامل للتنقل بلوحة التحكم

## الألوان

### الألوان الرئيسية
```dart
static const Color netflixRed = Color(0xFFE50914);
static const Color netflixBlack = Color(0xFF141414);
static const Color netflixDark = Color(0xFF181818);
static const Color netflixGray = Color(0xFF2F2F2F);
static const Color netflixLightGray = Color(0xFFB3B3B3);
static const Color netflixWhite = Color(0xFFFFFFFF);
```

### الاستخدام
- **netflixRed**: للأزرار الرئيسية، عناصر التركيز، والعلامات التجارية
- **netflixBlack**: للخلفية الرئيسية
- **netflixDark**: للخلفيات الثانوية
- **netflixGray**: للفواصل والحدود
- **netflixLightGray**: للنصوص الثانوية
- **netflixWhite**: للنصوص الرئيسية والأيقونات

## النصوص

### أحجام النصوص للشاشات الذكية
- Display Large: 56px
- Display Medium: 48px
- Display Small: 40px
- Headline Large: 32px
- Headline Medium: 28px
- Headline Small: 24px
- Title Large: 20px
- Title Medium: 18px
- Title Small: 16px
- Body Large: 16px
- Body Medium: 14px
- Body Small: 12px
- Label Large: 14px
- Label Medium: 12px
- Label Small: 10px

### أحجام النصوص للموبايل
- Display Large: 48px
- Display Medium: 40px
- Display Small: 32px
- Headline Large: 28px
- Headline Medium: 24px
- Headline Small: 20px
- Title Large: 18px
- Title Medium: 16px
- Title Small: 14px
- Body Large: 14px
- Body Medium: 12px
- Body Small: 10px
- Label Large: 12px
- Label Medium: 10px
- Label Small: 8px

## الأزرار

### الأزرار الرئيسية
- خلفية بيضاء
- نص أسود
- زوايا مربعة (4px)
- حجم كبير للشاشات الذكية
- حدود عند التركيز

### الأزرار الثانوية
- خلفية شفافة
- نص أبيض
- حدود رمادية
- حجم متوسط للشاشات الذكية
- حدود حمراء عند التركيز

### أزرار التحكم في المشغل
- دائرية
- خلفية سوداء شبه شفافة
- أيقونة بيضاء
- حدود حمراء عند التركيز

## البطاقات

### بطاقات الأفلام
- زوايا مربعة (4px)
- حدود بيضاء عند التركيز
- ظل عند التركيز
- تدرج لوني في الأسفل
- زر تشغيل عند التركيز

### أبعاد البطاقات
- الشاشات الذكية: 200x300px
- الموبايل: 160x240px

## التركيز والتنقل

### مؤشر التركيز
- حدود بيضاء (3px)
- ظل أبيض شفاف
- تأثير تكبير (1.08x)
- مدة الحركة: 200ms

### التنقل
- دعم كامل لأزرار D-Pad
- ترتيب منطقي للتنقل
- تركيز تلقائي على العناصر الرئيسية
- تمرير تلقائي للعنصر المركز

## المشغل

### عناصر التحكم
- أزرار كبيرة وواضحة
- شريط تقدم أحمر
- معلومات الوقت
- إخفاء تلقائي بعد 4 ثواني

### أبعاد الأزرار
- الشاشات الذكية: 64x64px (عادي)، 80x80px (كبير)
- الموبايل: 48x48px (عادي)، 64x64px (كبير)

## التدرجات اللونية

### تدرج الخلفية
```dart
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Colors.black.withOpacity(0.3),
    Colors.black.withOpacity(0.7),
    NetflixTheme.netflixBlack,
  ],
  stops: const [0.0, 0.5, 1.0],
)
```

### تدرج البطاقات
```dart
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Colors.transparent,
    Colors.black.withOpacity(0.8),
  ],
)
```

## كيفية الاستخدام

### تطبيق الثيم
```dart
MaterialApp(
  theme: NetflixTheme.tvTheme, // للشاشات الذكية
  // أو
  theme: NetflixTheme.mobileTheme, // للموبايل
  home: NetflixHomeScreen(),
)
```

### استخدام الشاشات
```dart
// الشاشة الرئيسية
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NetflixHomeScreen()),
);

// شاشة التفاصيل
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NetflixDetailsScreen(movie: movie)),
);

// شاشة المشغل
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NetflixPlayerScreen(
    videoUrl: movie.videoUrl,
    title: movie.title,
  )),
);
```

## المميزات الرئيسية

### 1. تصميم Netflix الأصلي
- ألوان Netflix الدقيقة
- أنماط النصوص المطابقة
- تأثيرات بصرية مماثلة

### 2. دعم الشاشات الذكية
- أزرار كبيرة وواضحة
- دعم كامل للتنقل بلوحة التحكم
- مؤشرات تركيز واضحة

### 3. تجربة مستخدم سلسة
- حركات سلسة
- تمرير تلقائي
- تركيز تلقائي

### 4. متجاوب
- تكيف تلقائي مع حجم الشاشة
- أحجام مناسبة لكل نوع جهاز
- تخطيطات مرنة

## ملاحظات إضافية

### الخطوط
- يُنصح باستخدام خط NetflixSans
- يمكن استبداله بخط Cairo للعربية

### الصور
- يُنصح باستخدام صور عالية الجودة
- نسبة العرض للارتفاع: 2:3 للبطاقات
- دعم الصور المحملة من الشبكة

### الفيديو
- دعم البث المباشر
- دعم البث المسجل
- دعم الترجمة

## التحسينات المستقبلية

### أولوية عالية
1. إضافة المزيد من التأثيرات البصرية
2. تحسين أداء التمرير
3. إضافة دعم للصوت

### أولوية متوسطة
4. تحسين واجهة البحث
5. إضافة دعم للقوائم
6. تحسين إدارة الذاكرة

### أولوية منخفضة
7. إضافة ميزات إضافية
8. تحسين الأداء العام
9. إضافة دعم للغات الأخرى
