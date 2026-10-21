import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../core/theme.dart';

class AuthScreen extends StatefulWidget {
  final Widget child;
  const AuthScreen({super.key, required this.child});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>();
    if (!settings.useBiometrics) return;

    if (state == AppLifecycleState.paused) {
      // Re-lock the app when sent to the background
      if (mounted) {
        setState(() {
          isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed && !isAuthenticated && !_isAuthenticating) {
      // Automatically prompt for authentication when restored
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.useBiometrics) {
      if (mounted) {
        setState(() {
          isAuthenticated = true;
        });
      }
      return;
    }

    try {
      final isSupported = await auth.isDeviceSupported() || await auth.canCheckBiometrics;
      if (!isSupported) {
        // Device lacks hardware or credentials — allow access without locking user out permanently
        if (mounted) {
          setState(() {
            isAuthenticated = true;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isAuthenticating = true;
        });
      }
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (mounted) {
        setState(() {
          isAuthenticated = didAuthenticate;
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SettingsProvider>().useBiometrics) {
      return widget.child;
    }

    if (isAuthenticated) {
      return widget.child;
    }
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: AppTheme.onSurfaceMuted),
              const SizedBox(height: 24),
              Text('Antigravity is Locked', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Authenticate with your fingerprint, face, or device PIN to continue.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                    ),
              ),
              const SizedBox(height: 32),
              if (!_isAuthenticating)
                OutlinedButton.icon(
                  onPressed: _checkAuth,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                const CircularProgressIndicator(color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}
