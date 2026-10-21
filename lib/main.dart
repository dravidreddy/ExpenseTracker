// lib/main.dart
//
// ─── Antigravity ─────────────────────────────────────────────────────────────
// Zero-friction, fully offline expense tracker.
// Log an expense in under 3 seconds.
//
// Architecture:
//   main.dart            → Bootstrap + root widget
//   core/                → Theme, categorizer engine, currency
//   data/                → Models, database helper
//   providers/           → ChangeNotifier state (expense, settings)
//   screens/             → All 4 screens
//   widgets/             → Shared reusable widgets

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/categorizer.dart';
import 'core/theme.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/auth_screen.dart';
import 'widgets/bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global Crash Interception & Error Boundary ───────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Antigravity Captured FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Antigravity Captured Async Error: $error\n$stack');
    return true; // Prevents unhandled async exceptions from killing the process
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your offline data is safe. Please restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 14,
                ),
              ),
              if (!kReleaseMode) ...[
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  };

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Load keyword dictionary before first frame
  await Categorizer.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..init(),
        ),
      ],
      child: const AntigravityApp(),
    ),
  );
}

class AntigravityApp extends StatelessWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthScreen(child: _Shell()),
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────
//
// IndexedStack keeps all three tabs alive — no state lost when switching.

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  static const _screens = [
    HomeScreen(),
    TimelineScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _tab,
        children: _screens,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}
