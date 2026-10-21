// lib/screens/teach_antigravity_screen.dart
//
// ─── Teach Antigravity: Interactive Vocabulary Studio ─────────────────────────
//
// Allows users to test and teach custom keywords to Antigravity's offline engine.
// System dictionary keywords are kept internal; the studio interactively checks
// words, shows category matches, and enables one-tap learning for new phrases.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/categorizer.dart';
import '../core/theme.dart';
import '../data/models/category_meta.dart';

class TeachAntigravityScreen extends StatefulWidget {
  const TeachAntigravityScreen({super.key});

  @override
  State<TeachAntigravityScreen> createState() => _TeachAntigravityScreenState();
}

class _TeachAntigravityScreenState extends State<TeachAntigravityScreen> {
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();

  String _currentQuery = '';
  CategoryMeta? _matchedCategory;
  bool _isExactMatch = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final text = _inputCtrl.text.trim();
    if (text == _currentQuery) return;

    setState(() {
      _currentQuery = text;
      if (text.isEmpty) {
        _matchedCategory = null;
        _isExactMatch = false;
      } else {
        _isExactMatch = Categorizer.instance.containsExactKeyword(text);
        if (_isExactMatch) {
          _matchedCategory = Categorizer.instance.getCategoryForExactKeyword(text);
        } else {
          _matchedCategory = Categorizer.instance.matchWord(text);
        }
      }
    });
  }

  void _teachKeyword(CategoryMeta category) {
    final word = _currentQuery.trim();
    if (word.isEmpty) return;

    final added = Categorizer.instance.addKeyword(category.id, word);
    HapticFeedback.mediumImpact();

    if (added) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Antigravity learned "$word" → ${category.label}!',
                  style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
            ],
          ),
        ),
      );

      _onInputChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$word" is already in the dictionary under ${category.label}.'),
          backgroundColor: AppTheme.surfaceVariant,
        ),
      );
    }
  }

  void _reassignKeyword(CategoryMeta newCategory) {
    final word = _currentQuery.trim();
    if (word.isEmpty) return;

    // Remove from all categories first to ensure clean reassignment
    for (final cat in Categorizer.instance.categories) {
      Categorizer.instance.removeKeyword(cat.id, word);
    }
    Categorizer.instance.addKeyword(newCategory.id, word);
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Text(newCategory.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reassigned "$word" → ${newCategory.label}!',
                style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
          ],
        ),
      ),
    );

    _onInputChanged();
  }

  @override
  Widget build(BuildContext context) {
    final categories = Categorizer.instance.categories.where((c) => c.id != 'misc').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Teach Antigravity'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow and Headline
              Text(
                'DICTIONARY & VOCABULARY',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: AppTheme.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Teach Antigravity',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Train the offline categorization engine on your custom habits, local food items, energy drinks, and daily shortcuts.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 28),

              // ── Input Studio Container (Double-Bezel Hardware Architecture) ──
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test or Teach a Phrase',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Input Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.psychology_rounded,
                              color: AppTheme.onSurfaceMuted,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                focusNode: _focusNode,
                                style: Theme.of(context).textTheme.titleMedium,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. masala dosa, redbull, monster...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.onSurfaceMuted,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_currentQuery.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _inputCtrl.clear();
                                  _focusNode.requestFocus();
                                },
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: AppTheme.onSurfaceMuted,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Interactive Suggestions / Training Card ──────────────────────
              if (_currentQuery.isEmpty) ...[
                // Empty state tip with quick chips
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFFFBBF24),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'How it works',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Type any item above. If Antigravity recognizes it, we\'ll display its category. If not, tap any category below to immediately teach it!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceMuted,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Try testing these:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'idly',
                          'masala dosa',
                          'redbull',
                          'monster energy',
                          'metro pass',
                          'rapido',
                        ].map((sample) {
                          return ActionChip(
                            label: Text(sample),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: const BorderSide(color: AppTheme.border),
                            labelStyle: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
                            onPressed: () {
                              _inputCtrl.text = sample;
                              _inputCtrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: sample.length),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ] else if (_matchedCategory != null) ...[
                // Word is already recognized
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Already Recognized!',
                                  style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Antigravity maps "$_currentQuery" to ${_matchedCategory!.label}',
                                  style: const TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _matchedCategory!.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _matchedCategory!.color.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_matchedCategory!.emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  _matchedCategory!.label,
                                  style: TextStyle(
                                    color: _matchedCategory!.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      Text(
                        'Want this in a different category? Tap to reassign:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories
                            .where((c) => c.id != _matchedCategory!.id)
                            .map((cat) {
                          return ActionChip(
                            avatar: Text(cat.emoji),
                            label: Text(cat.label),
                            backgroundColor: AppTheme.surfaceVariant,
                            side: const BorderSide(color: AppTheme.border),
                            labelStyle: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
                            onPressed: () => _reassignKeyword(cat),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // New keyword! Prompt user to assign
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accent.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Keyword!',
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Which category should "$_currentQuery" belong to?',
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: categories.map((cat) {
                          return ActionChip(
                            avatar: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                            label: Text(cat.label),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(color: cat.color.withValues(alpha: 0.5)),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cat.color,
                            ),
                            onPressed: () => _teachKeyword(cat),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),

              // ── Reset to Defaults ────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Reset Custom Vocabulary?'),
                      content: const Text(
                        'This will reset your dictionary back to the bundled standard vocabulary defaults.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceMuted)),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                          child: const Text('Reset', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await Categorizer.instance.resetCustomKeywords();
                    if (!mounted) return;
                    setState(() {
                      _onInputChanged();
                    });
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Dictionary reset to defaults.')),
                    );
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Custom Vocabulary'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.onSurfaceMuted,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
