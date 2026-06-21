import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/movie_provider.dart';
import 'screens/home_screen.dart';
import 'screens/netflix_home_screen.dart';
import 'theme/netflix_theme.dart';
import 'widgets/app_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load Cairo font once to avoid jank on first render
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.cairo()]);
  } catch (e) {
    debugPrint('Failed to preload Cairo font: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
      ],
      child: const TvPlusApp(),
    ),
  );
}

class TvPlusApp extends StatelessWidget {
  const TvPlusApp({super.key});

  // ── Static theme – created once, never rebuilt ──
  static final _theme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00E5FF),
    scaffoldBackgroundColor: const Color(0xFF070514),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5FF),
      brightness: Brightness.dark,
      primary: const Color(0xFF00E5FF),
      onPrimary: const Color(0xFF00373F),
      secondary: const Color(0xFFFF2D55),
      onSecondary: const Color(0xFF4C0012),
      surface: const Color(0xFF070514),
      onSurface: const Color(0xFFF0EFFF),
      surfaceVariant: const Color(0xFF13112B),
      onSurfaceVariant: const Color(0xFFA59EC6),
    ),
    textTheme: GoogleFonts.cairoTextTheme().apply(
      bodyColor: const Color(0xFFF0EFFF),
      displayColor: const Color(0xFFF0EFFF),
    ),
    useMaterial3: true,
    focusColor: const Color(0xFF00E5FF),
    hoverColor: const Color(0xFF00E5FF),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TVplus',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: const AppWrapper(child: HomeScreen()),
      builder: (context, child) {
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) => null,
              ),
            },
            child: Focus(
              autofocus: true,
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
