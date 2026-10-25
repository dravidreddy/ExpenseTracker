import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _errorMessage;
  int _failedAttempts = 0;

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
      // Only lock if we are NOT actively in the middle of a biometric system prompt
      if (!_isAuthenticating && mounted) {
        setState(() {
          isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed && !isAuthenticated && !_isAuthenticating) {
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.useBiometrics) {
      if (mounted) {
        setState(() {
          isAuthenticated = true;
          _errorMessage = null;
        });
      }
      return;
    }

    if (_isAuthenticating) return;

    try {
      if (mounted) {
        setState(() {
          _isAuthenticating = true;
          _errorMessage = null;
        });
      }

      final isSupported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        // Hardware does not support biometrics on this device
        if (mounted) {
          setState(() {
            isAuthenticated = true;
            _isAuthenticating = false;
          });
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to access your Expense Tracker ledger',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (mounted) {
        setState(() {
          isAuthenticated = didAuthenticate;
          _isAuthenticating = false;
          if (didAuthenticate) {
            _errorMessage = null;
            _failedAttempts = 0;
            HapticFeedback.lightImpact();
          } else {
            _failedAttempts++;
            _errorMessage = 'Authentication was not completed. Tap below to retry.';
            HapticFeedback.mediumImpact();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _failedAttempts++;
          _errorMessage = 'Biometric sensor error: ${e.toString().replaceAll('PlatformException(', '').replaceAll(')', '')}';
        });
      }
    }
  }

  Future<void> _emergencyBypass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bypass Biometric Lock?'),
        content: const Text(
          'If your biometric sensor is malfunctioning, you can temporarily disable biometric lock to access your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Disable Lock', style: TextStyle(color: AppTheme.background)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SettingsProvider>().setBiometrics(false);
      setState(() {
        isAuthenticated = true;
        _errorMessage = null;
      });
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
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Double-Bezel Hardware Shield Container ─────────────────
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(29.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stormbreaker App Icon Badge with Glow Aura
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.08),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title & Subtitle
                        Text(
                          'Expense Tracker Locked',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                color: AppTheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Scan your fingerprint, face, or enter device credentials to access your offline ledger.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceMuted,
                                height: 1.4,
                              ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFCA5A5),
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // ── Primary Island CTA Button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isAuthenticating ? null : () => _checkAuth(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.onSurface,
                              foregroundColor: AppTheme.background,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: _isAuthenticating
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.background,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Unlock Ledger',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(alpha: 0.12),
                                        ),
                                        child: const Icon(
                                          Icons.fingerprint_rounded,
                                          size: 18,
                                          color: AppTheme.background,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Secondary action: device credential or emergency bypass if failed
                        if (_failedAttempts >= 2) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _emergencyBypass,
                            child: Text(
                              'Can\'t authenticate? Disable Lock',
                              style: TextStyle(
                                color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
