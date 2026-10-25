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
                  'Expense Tracker learned "$word" → ${category.label}!',
                  style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
            ],
          ),
        ),
      );

      _inputCtrl.clear();
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

    _inputCtrl.clear();
    _onInputChanged();
  }

  Future<void> _openCreateCategorySheet() async {
    HapticFeedback.lightImpact();
    final newCat = await showModalBottomSheet<CategoryMeta>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CategoryEditorSheet(),
    );

    if (newCat != null && mounted) {
      final success = Categorizer.instance.addCustomCategory(newCat);
      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                Text(newCat.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Created category "${newCat.label}"!',
                    style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _openEditCategorySheet(CategoryMeta category) async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<_CategoryEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditorSheet(existingCategory: category),
    );

    if (result != null && mounted) {
      if (result.isDelete) {
        Categorizer.instance.deleteCustomCategory(category.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed category "${category.label}".'),
            backgroundColor: AppTheme.surfaceVariant,
          ),
        );
      } else if (result.updatedCategory != null) {
        Categorizer.instance.updateCategory(result.updatedCategory!);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                Text(result.updatedCategory!.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Updated category "${result.updatedCategory!.label}"!',
                    style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _openKeywordOptionsSheet({
    required String keyword,
    required CategoryMeta currentCategory,
  }) async {
    HapticFeedback.lightImpact();
    final categories = Categorizer.instance.categories.where((c) => c.id != 'misc').toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF2E2E2E), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Keyword Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: currentCategory.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(currentCategory.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           '"$keyword"',
                           style: const TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.w700,
                             color: AppTheme.onSurface,
                           ),
                         ),
                         const SizedBox(height: 2),
                         Text(
                           'Currently taught to ${currentCategory.label}',
                           style: TextStyle(
                             fontSize: 12,
                             color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                           ),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     onPressed: () => Navigator.pop(ctx),
                     icon: const Icon(Icons.close_rounded, size: 20),
                     color: AppTheme.onSurfaceMuted,
                   ),
                 ],
               ),
               const SizedBox(height: 22),
               const Divider(color: Colors.white12),
               const SizedBox(height: 14),

               // Reassign Section
               Text(
                 'REASSIGN TO ANOTHER CATEGORY',
                 style: TextStyle(
                   fontSize: 11,
                   letterSpacing: 1.2,
                   fontWeight: FontWeight.w600,
                   color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                 ),
               ),
               const SizedBox(height: 12),
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: categories
                     .where((c) => c.id != currentCategory.id)
                     .map((targetCat) {
                   return ActionChip(
                     avatar: Text(targetCat.emoji),
                     label: Text(targetCat.label),
                     backgroundColor: AppTheme.surfaceVariant,
                     side: const BorderSide(color: AppTheme.border),
                     labelStyle: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
                     onPressed: () {
                       HapticFeedback.mediumImpact();
                       Categorizer.instance.removeKeyword(currentCategory.id, keyword);
                       Categorizer.instance.addKeyword(targetCat.id, keyword);
                       Navigator.pop(ctx);
                       setState(() {});
                       ScaffoldMessenger.of(context).clearSnackBars();
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           backgroundColor: AppTheme.surfaceVariant,
                           behavior: SnackBarBehavior.floating,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                           content: Row(
                             children: [
                               Text(targetCat.emoji, style: const TextStyle(fontSize: 20)),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   'Moved "$keyword" → ${targetCat.label}!',
                                   style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500),
                                 ),
                               ),
                               const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                             ],
                           ),
                         ),
                       );
                     },
                   );
                 }).toList(),
               ),
               const SizedBox(height: 24),

               // Delete action
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton.icon(
                   onPressed: () {
                     HapticFeedback.mediumImpact();
                     Categorizer.instance.removeKeyword(currentCategory.id, keyword);
                     Navigator.pop(ctx);
                     setState(() {});
                     ScaffoldMessenger.of(context).clearSnackBars();
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Removed "$keyword" from ${currentCategory.label}.'),
                         backgroundColor: AppTheme.surfaceVariant,
                         duration: const Duration(seconds: 2),
                       ),
                     );
                   },
                   icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                   label: const Text('Delete Keyword', style: TextStyle(color: Color(0xFFEF4444))),
                   style: OutlinedButton.styleFrom(
                     side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                   ),
                 ),
               ),
             ],
           ),
         ),
       ),
     );
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
        title: const Text('Teach Vocabulary'),
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
                'Teach Vocabulary',
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
                        'Type any item above. If Expense Tracker recognizes it, we\'ll display its category. If not, tap any category below to immediately teach it!',
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
                                  'Expense Tracker maps "$_currentQuery" to ${_matchedCategory!.label}',
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

              const SizedBox(height: 36),
              const Divider(),
              const SizedBox(height: 28),

              // ── CATEGORIES MANAGEMENT STUDIO ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMIZE & ORGANIZE',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              letterSpacing: 1.4,
                              color: AppTheme.onSurfaceMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _openCreateCategorySheet,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.onSurface,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Add Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // List of all categories
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: Categorizer.instance.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final cat = Categorizer.instance.categories[i];
                  final isMisc = cat.id == 'misc';
                  final taught = Categorizer.instance.getUserTaughtKeywords(cat.id);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Emoji, Label, Custom badge, Edit Category button
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cat.color.withValues(alpha: 0.3)),
                              ),
                              child: Center(
                                child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cat.label,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (cat.isCustom) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cat.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Custom',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: cat.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isMisc)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: AppTheme.onSurfaceMuted,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit category',
                                onPressed: () => _openEditCategorySheet(cat),
                              ),
                          ],
                        ),

                        // Body: User taught keywords ONLY
                        if (isMisc) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Default fallback category',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ] else if (taught.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'No custom keywords taught yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: taught.map((kw) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cat.color.withValues(alpha: 0.3)),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _openKeywordOptionsSheet(keyword: kw, currentCategory: cat),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            kw,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: cat.color,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              Categorizer.instance.removeKeyword(cat.id, kw);
                                              setState(() {});
                                              ScaffoldMessenger.of(context).clearSnackBars();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Removed "$kw" from ${cat.label}.'),
                                                  backgroundColor: AppTheme.surfaceVariant,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: cat.color.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),
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

// ─────────────────────────────────────────────────────────────────────────────
// Category Editor Bottom Sheet (Agency-Grade Studio)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryEditResult {
  final bool isDelete;
  final CategoryMeta? updatedCategory;

  _CategoryEditResult.update(this.updatedCategory) : isDelete = false;
  _CategoryEditResult.delete() : isDelete = true, updatedCategory = null;
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.existingCategory});
  final CategoryMeta? existingCategory;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedEmoji;
  late Color _selectedColor;

  static const _emojiPalette = [
    '🏋️', '🎮', '🐾', '📚', '🍿', '☕', '✈️', '💊',
    '🎨', '🌿', '👔', '📱', '🚗', '🎁', '🍺', '🍕',
    '💻', '💡', '🛠️', '🧘', '🎸', '🎟️', '⚽', '🪴',
    '🛒', '⚡', '🏥', '🏖️', '🎬', '🍔', '🍼', '🚲',
  ];

  static const _colorPalette = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Electric Blue
    Color(0xFF8B5CF6), // Amethyst Purple
    Color(0xFFEC4899), // Rose
    Color(0xFFF59E0B), // Amber Flame
    Color(0xFF06B6D4), // Cyan
    Color(0xFF14B8A6), // Teal
    Color(0xFFF43F5E), // Coral
    Color(0xFFA855F7), // Violet
    Color(0xFFEAB308), // Gold
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingCategory?.label ?? '');
    _selectedEmoji = widget.existingCategory?.emoji ?? '🏋️';
    _selectedColor = widget.existingCategory?.color ?? _colorPalette[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (widget.existingCategory != null) {
      final updated = widget.existingCategory!.copyWith(
        label: name,
        emoji: _selectedEmoji,
        color: _selectedColor,
      );
      Navigator.pop(context, _CategoryEditResult.update(updated));
    } else {
      final id = 'cat_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch % 10000}';
      final newCat = CategoryMeta(
        id: id,
        label: name,
        emoji: _selectedEmoji,
        color: _selectedColor,
        keywords: [name.toLowerCase()],
        isCustom: true,
      );
      Navigator.pop(context, newCat);
    }
  }

  Future<void> _delete() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${widget.existingCategory?.label}"?'),
        content: const Text(
          'This custom category will be removed. Existing expenses in this category will retain their category ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, _CategoryEditResult.delete());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCategory != null;
    final isCustom = widget.existingCategory?.isCustom ?? false;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: viewInsets),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Customize Category' : 'New Category',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Preview Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _selectedColor.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedEmoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          _nameCtrl.text.trim().isEmpty ? 'Category Preview' : _nameCtrl.text.trim(),
                          style: TextStyle(
                            color: _selectedColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name Input
                Text(
                  'Category Name',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    style: Theme.of(context).textTheme.titleMedium,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Gym, Gaming, Pets, Books',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Emoji Picker
                Text(
                  'Choose Icon',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojiPalette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final emoji = _emojiPalette[i];
                      final isSelected = emoji == _selectedEmoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedEmoji = emoji);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor.withValues(alpha: 0.25) : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? _selectedColor : AppTheme.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Color Palette
                Text(
                  'Choose Color',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorPalette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final col = _colorPalette[i];
                      final isSelected = col == _selectedColor;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedColor = col);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: col.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.onSurface,
                      foregroundColor: AppTheme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Category',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                if (isCustom) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Delete Category',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33EF4444)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
