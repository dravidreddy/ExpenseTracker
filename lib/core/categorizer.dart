// lib/core/categorizer.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member
//
// ─── Offline Auto-Categorization Engine ──────────────────────────────────────
//
// 1. Normalise: lowercase + strip punctuation.
// 2. Match: substring scan against the keyword dictionary.
// 3. Fallback: "misc" if no match found.
//
// ── Keyword Persistence (Phase 1) ─────────────────────────────────────────────
//
// We persist only the USER'S DELTA vs the bundled categories.json, not the
// entire keyword list. This has two key advantages:
//
//   1. App updates that add new bundled keywords still take effect.
//   2. The prefs entry stays tiny regardless of how many categories exist.
//
// Delta format stored under key "keyword_delta_v1":
//   {
//     "food":  { "added": ["kfc", "mcd"], "removed": ["chai"] },
//     "bike":  { "added": ["cng"],        "removed": []       }
//   }
//
// On init():
//   a. Load JSON asset → base _categories
//   b. Read delta from SharedPreferences
//   c. Replay: remove the "removed" set, union the "added" set
//
// All matching is pure Dart – zero network calls, zero AI APIs.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/category_meta.dart';

export 'dart:ui' show Color;

class Categorizer {
  Categorizer._();
  static final Categorizer instance = Categorizer._();

  List<CategoryMeta> _categories = [];
  bool _loaded = false;

  static const _prefKey = 'keyword_delta_v1';

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_loaded) return;

    // Step 1 – load bundled defaults.
    final raw = await rootBundle.loadString('assets/data/categories.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _categories = (json['categories'] as List)
        .map((e) => CategoryMeta.fromJson(e as Map<String, dynamic>))
        .toList();

    // Step 2 – replay persisted user customisations on top.
    await _loadKeywords();

    _loaded = true;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  List<CategoryMeta> get categories => List.unmodifiable(_categories);

  /// Returns the matched [CategoryMeta] for the given description text.
  /// Always returns a non-null value (fallback = "misc").
  CategoryMeta categorize(String description) {
    final normalised = _normalise(description);
    if (normalised.isEmpty) return _miscCategory;

    for (final cat in _categories) {
      if (cat.id == 'misc') continue; // check misc last
      for (final keyword in cat.keywords) {
        if (normalised.contains(keyword)) {
          return cat;
        }
      }
    }
    return _miscCategory;
  }

  CategoryMeta get _miscCategory =>
      _categories.firstWhere((c) => c.id == 'misc',
          orElse: () => const CategoryMeta(
                id: 'misc',
                label: 'Other',
                emoji: '🏷️',
                color: Color(0xFF9CA3AF),
                keywords: [],
              ));

  // ── Keyword Manager ───────────────────────────────────────────────────────

  /// Add [keyword] to [categoryId]. Returns true if added (not a duplicate).
  bool addKeyword(String categoryId, String keyword) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return false;
    final kw = keyword.trim().toLowerCase();
    if (kw.isEmpty) return false;
    if (_categories[idx].keywords.contains(kw)) return false;

    _categories[idx] = _categories[idx].copyWith(
      keywords: [..._categories[idx].keywords, kw],
    );
    _saveKeywords(); // fire-and-forget — never blocks the UI
    return true;
  }

  /// Remove [keyword] from [categoryId]. Returns true if removed.
  bool removeKeyword(String categoryId, String keyword) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return false;
    final updated = [..._categories[idx].keywords]..remove(keyword);
    _categories[idx] = _categories[idx].copyWith(keywords: updated);
    _saveKeywords(); // fire-and-forget — never blocks the UI
    return true;
  }

  /// Resets all custom keywords back to bundled defaults.
  Future<void> resetCustomKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      _loaded = false;
      await init();
    } catch (_) {}
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  /// Computes the diff between current state and bundled defaults, then
  /// writes it to SharedPreferences.
  Future<void> _saveKeywords() async {
    try {
      // Re-read bundled defaults to compute the delta accurately.
      final raw = await rootBundle.loadString('assets/data/categories.json');
      final jsonData = jsonDecode(raw) as Map<String, dynamic>;
      final defaults = (jsonData['categories'] as List)
          .map((e) => CategoryMeta.fromJson(e as Map<String, dynamic>))
          .toList();

      final delta = <String, Map<String, List<String>>>{};

      for (final current in _categories) {
        final def = defaults.firstWhere(
          (d) => d.id == current.id,
          orElse: () => current, // brand-new category — treat all as added
        );
        final defaultSet = def.keywords.toSet();
        final currentSet = current.keywords.toSet();

        final added = currentSet.difference(defaultSet).toList()..sort();
        final removed = defaultSet.difference(currentSet).toList()..sort();

        if (added.isNotEmpty || removed.isNotEmpty) {
          delta[current.id] = {'added': added, 'removed': removed};
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(delta));
    } catch (_) {
      // Never crash the app over a persistence failure — silently swallow.
    }
  }

  /// Reads the saved delta from SharedPreferences and applies it to the
  /// already-loaded [_categories] list.
  Future<void> _loadKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return; // nothing saved yet

      final delta = jsonDecode(raw) as Map<String, dynamic>;

      for (int i = 0; i < _categories.length; i++) {
        final catId = _categories[i].id;
        if (!delta.containsKey(catId)) continue;

        final entry = delta[catId] as Map<String, dynamic>;
        final added = List<String>.from(entry['added'] as List? ?? []);
        final removed = List<String>.from(entry['removed'] as List? ?? []);

        var keywords = [..._categories[i].keywords];
        // Apply removals first so they can't cancel out a fresh addition.
        keywords.removeWhere((kw) => removed.contains(kw));
        for (final kw in added) {
          if (!keywords.contains(kw)) keywords.add(kw);
        }

        _categories[i] = _categories[i].copyWith(keywords: keywords);
      }
    } catch (_) {
      // Corrupted prefs — silently fall back to bundled defaults.
    }
  }

  // ── Normalisation ─────────────────────────────────────────────────────────

  static final _punctuationRe = RegExp(r'[^\w\s]');

  String _normalise(String input) =>
      input.toLowerCase().replaceAll(_punctuationRe, '').trim();

  // ── Test backdoor ──────────────────────────────────────────────────────────
  //
  // Resets the singleton's mutable fields so unit tests can call init()
  // multiple times within one process, simulating app restarts.
  @visibleForTesting
  void resetForTesting() {
    _categories = [];
    _loaded = false;
  }
}
