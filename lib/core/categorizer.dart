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
  static const _customCatPrefKey = 'custom_categories_v1';

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_loaded) return;

    // Step 1 – load bundled defaults.
    final raw = await rootBundle.loadString('assets/data/categories.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _categories = (json['categories'] as List)
        .map((e) => CategoryMeta.fromJson(e as Map<String, dynamic>))
        .toList();

    // Step 2 – replay custom categories created by user.
    await _loadCustomCategories();

    // Step 3 – replay persisted user keyword customisations on top.
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

  /// Checks if [word] is already known by exact or partial match.
  /// Returns the matched CategoryMeta if found, or null if unmapped.
  CategoryMeta? matchWord(String word) {
    final normalised = _normalise(word);
    if (normalised.isEmpty) return null;

    // Check exact keyword match first
    for (final cat in _categories) {
      if (cat.id == 'misc') continue;
      if (cat.keywords.contains(normalised)) {
        return cat;
      }
    }

    // Then check substring
    for (final cat in _categories) {
      if (cat.id == 'misc') continue;
      for (final kw in cat.keywords) {
        if (normalised.contains(kw) || (kw.length >= 3 && normalised.contains(kw))) {
          return cat;
        }
      }
    }

    return null;
  }

  /// Returns true if the exact keyword already exists in any category.
  bool containsExactKeyword(String word) {
    final kw = word.trim().toLowerCase();
    for (final cat in _categories) {
      if (cat.keywords.contains(kw)) return true;
    }
    return false;
  }

  /// Returns which category currently contains this exact keyword.
  CategoryMeta? getCategoryForExactKeyword(String word) {
    final kw = word.trim().toLowerCase();
    for (final cat in _categories) {
      if (cat.keywords.contains(kw)) return cat;
    }
    return null;
  }

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
    if (_categories[idx].isCustom) {
      _saveCustomCategories();
    }
    _saveKeywords(); // fire-and-forget — never blocks the UI
    return true;
  }

  /// Remove [keyword] from [categoryId]. Returns true if removed.
  bool removeKeyword(String categoryId, String keyword) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return false;
    final updated = [..._categories[idx].keywords]..remove(keyword);
    _categories[idx] = _categories[idx].copyWith(keywords: updated);
    if (_categories[idx].isCustom) {
      _saveCustomCategories();
    }
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

  // ── Custom Category Manager ────────────────────────────────────────────────

  /// Returns true if the category with [id] is a user-created custom category.
  bool isCustomCategory(String id) {
    final cat = _categories.firstWhere((c) => c.id == id, orElse: () => _miscCategory);
    return cat.isCustom;
  }

  /// Adds a new custom category. Inserts at the top so user categories take priority.
  bool addCustomCategory(CategoryMeta category) {
    if (_categories.any((c) => c.id == category.id)) return false;

    final customCat = category.copyWith(isCustom: true);
    _categories.insert(0, customCat);

    _saveCustomCategories();
    return true;
  }

  /// Updates an existing category (label, emoji, color).
  bool updateCategory(CategoryMeta updated) {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return false;
    _categories[idx] = updated;
    _saveCustomCategories();
    return true;
  }

  /// Deletes a custom category (cannot delete 'misc' or built-in system categories).
  bool deleteCustomCategory(String categoryId) {
    if (categoryId == 'misc') return false;
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return false;
    _categories.removeAt(idx);
    _saveCustomCategories();
    return true;
  }

  /// Resets custom categories.
  Future<void> resetCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customCatPrefKey);
      _loaded = false;
      await init();
    } catch (_) {}
  }

  Future<void> _saveCustomCategories() async {
    try {
      final customList = _categories.where((c) => c.isCustom).map((c) => c.toJson()).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customCatPrefKey, jsonEncode(customList));
    } catch (_) {}
  }

  Future<void> _loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customCatPrefKey);
      if (raw == null || raw.isEmpty) return;

      final list = jsonDecode(raw) as List;

      for (final item in list) {
        final cat = CategoryMeta.fromJson(item as Map<String, dynamic>).copyWith(isCustom: true);
        final existingIdx = _categories.indexWhere((c) => c.id == cat.id);
        if (existingIdx != -1) {
          _categories[existingIdx] = cat;
        } else {
          _categories.insert(0, cat);
        }
      }
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
