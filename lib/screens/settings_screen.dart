// lib/screens/settings_screen.dart
//
// ─── Profile & Settings ───────────────────────────────────────────────────────
//
// • Currency selector
// • Keyword Manager per category

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/categorizer.dart';
import '../core/currency.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../core/export_service.dart';
import 'teach_antigravity_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'settings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: AppTheme.onSurfaceMuted,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 40),

              // ── Currency ────────────────────────────────────────────────
              const _SectionLabel(label: 'Currency'),
              const SizedBox(height: 12),
              _CurrencySelector(
                current: settings.currencyCode,
                onChanged: (code) => settings.setCurrency(code),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 32),

              // ── Security ────────────────────────────────────────────────
              const _SectionLabel(label: 'Security'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Require Biometrics to open',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Switch(
                    value: settings.useBiometrics,
                    onChanged: (val) => settings.setBiometrics(val),
                    activeThumbColor: AppTheme.accent,
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 32),

              // ── Data, Backup & Restore ──────────────────────────────────
              const _SectionLabel(label: 'Data & Backup'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ExportService.exportBackup(settings.currencyCode);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Backup failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.backup_rounded, color: AppTheme.accent),
                    label: const Text('Backup Ledger'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final count = await ExportService.importBackup();
                        if (!context.mounted) return;
                        if (count > 0) {
                          final provider = context.read<ExpenseProvider>();
                          await provider.refreshToday();
                          await provider.refreshMonthly();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Successfully restored $count expense records!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Restore failed: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.restore_page_rounded, color: AppTheme.accent),
                    label: const Text('Restore from Backup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ExportService.exportExpensesToCsv();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ExportService.exportExpensesToJson();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.data_object_rounded),
                    label: const Text('Export JSON'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 32),

              // ── Intelligence ───────────────────────────────────────────
              const _SectionLabel(label: 'Intelligence'),
              const SizedBox(height: 12),
              _MenuNavigationTile(
                icon: Icons.psychology_rounded,
                title: 'Teach Antigravity',
                subtitle: 'Train vocabulary, habits & custom dishes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeachAntigravityScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 32),

              // ── Privacy & Legal ─────────────────────────────────────────
              const _SectionLabel(label: 'Privacy & Legal'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showPrivacyPolicyDialog(context),
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Privacy Policy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.onSurface,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 32),

              // ── Danger Zone ─────────────────────────────────────────────
              const _SectionLabel(label: 'Danger Zone'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmResetAllData(context),
                icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 18),
                label: const Text(
                  'Reset All Data',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.accent),
            SizedBox(width: 10),
            Text('Privacy Policy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Antigravity operates with a strict offline-first, zero-knowledge architecture:\n\n'
            '• 100% Local Storage: All expenses are stored locally on your device in an encrypted SQLite database.\n\n'
            '• Biometrics: Fingerprint and screen lock authentication is handled purely on-device via the Android hardware Keystore. The app never accesses raw biometric data.\n\n'
            '• Zero Telemetry: No analytics SDKs, advertising networks, or remote servers exist.\n\n'
            '• Full Data Erasure: You have absolute control to export or permanently delete your financial records at any time.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmResetAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently erase all logged expenses, custom keywords, and restore the database to factory settings.\n\nThis action cannot be undone.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ExpenseProvider>().clearAllData();
              await Categorizer.instance.resetCustomKeywords();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been permanently wiped.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Wipe Everything'),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 1.5,
            color: AppTheme.onSurfaceMuted,
          ),
    );
  }
}

// ── Currency Selector ─────────────────────────────────────────────────────────

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({required this.current, required this.onChanged});
  final String current;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kSupportedCurrencies.map((c) {
        final selected = c.code == current;
        return GestureDetector(
          onTap: () => onChanged(c.code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.onSurface
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppTheme.onSurface : AppTheme.border,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  c.symbol,
                  style: TextStyle(
                    fontSize: 20,
                    color: selected
                        ? AppTheme.background
                        : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: selected
                            ? AppTheme.background
                            : AppTheme.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Menu Navigation Tile (Double-Bezel Luxury Component) ──────────────────────

class _MenuNavigationTile extends StatelessWidget {
  const _MenuNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: AppTheme.onSurface, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppTheme.onSurfaceMuted,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}
