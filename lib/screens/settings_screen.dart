// lib/screens/settings_screen.dart
//
// ─── Profile & Settings ───────────────────────────────────────────────────────
//
// • Currency selector
// • Keyword Manager per category

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/categorizer.dart';
import '../core/currency.dart';
import '../core/theme.dart';
import '../data/models/category_meta.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../core/export_service.dart';

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

              // ── Keyword Manager ─────────────────────────────────────────
              const _SectionLabel(label: 'Keyword Manager'),
              const SizedBox(height: 4),
              Text(
                'Teach Antigravity your habits.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              ...Categorizer.instance.categories
                  .where((c) => c.id != 'misc')
                  .map((cat) => _CategoryKeywordCard(category: cat)),

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

// ── Category Keyword Card ─────────────────────────────────────────────────────

class _CategoryKeywordCard extends StatefulWidget {
  const _CategoryKeywordCard({required this.category});
  final CategoryMeta category;

  @override
  State<_CategoryKeywordCard> createState() => _CategoryKeywordCardState();
}

class _CategoryKeywordCardState extends State<_CategoryKeywordCard> {
  bool _expanded = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final kw = _ctrl.text.trim().toLowerCase();
    if (kw.isEmpty) return;
    final added = Categorizer.instance.addKeyword(widget.category.id, kw);
    if (added) {
      _ctrl.clear();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keyword already exists.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch live category to reflect mutations
    final cat = Categorizer.instance.categories.firstWhere(
      (c) => c.id == widget.category.id,
      orElse: () => widget.category,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(cat.emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${cat.keywords.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Add keyword
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _ctrl,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addKeyword(),
                                style:
                                    Theme.of(context).textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Add keyword…',
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.accent, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _addKeyword,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.onSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppTheme.background,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Keyword chips
                        if (cat.keywords.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cat.keywords.map((kw) {
                              return _KeywordChip(
                                keyword: kw,
                                onDelete: () {
                                  Categorizer.instance
                                      .removeKeyword(cat.id, kw);
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            'No custom keywords yet.',
                            style:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.keyword, required this.onDelete});
  final String keyword;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keyword,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontSize: 13,
                ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
