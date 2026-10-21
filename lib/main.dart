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
