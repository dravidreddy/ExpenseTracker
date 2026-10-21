// test/categorizer_test.dart
//
// ─── Phase 1 Tests: Keyword Persistence ──────────────────────────────────────
//
// Tests for the Categorizer class covering:
//   1. Basic categorization (smoke tests)
//   2. addKeyword / removeKeyword mutations
//   3. Delta round-trip: persistence survives a simulated app restart
//   4. Delta accuracy: added and removed sets are stored correctly
//   5. Edge cases: duplicates, empty strings, unknown category ids
//
// We use SharedPreferences.setMockInitialValues() so tests run without
// a real device or emulator — no platform channel setup needed.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:antigravity/core/categorizer.dart';

// ── Test utilities ────────────────────────────────────────────────────────────

/// Resets the Categorizer singleton between tests to simulate an app restart.
void _reset() => Categorizer.instance.resetForTesting();

/// Initialises the Categorizer (loads JSON + replays prefs delta).
Future<void> _init() => Categorizer.instance.init();

/// Shorthand to get the keyword list for a category.
List<String> _keywords(String id) =>
    Categorizer.instance.categories.firstWhere((c) => c.id == id).keywords;

// ── Main ──────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Isolate each test: clear prefs and reset singleton.
    SharedPreferences.setMockInitialValues({});
    _reset();
  });

  // ── 1. Basic categorization ───────────────────────────────────────────────

  group('categorize() — baseline', () {
    test('matches a bundled food keyword', () async {
      await _init();
      expect(Categorizer.instance.categorize('zomato lunch').id, 'food');
    });

    test('matches a bundled travel keyword', () async {
      await _init();
      expect(Categorizer.instance.categorize('uber to office').id, 'travel');
    });

    test('falls back to misc for unknown text', () async {
      await _init();
      expect(Categorizer.instance.categorize('xyzzy quantum flux').id, 'misc');
    });

    test('returns misc for empty string', () async {
      await _init();
      expect(Categorizer.instance.categorize('').id, 'misc');
    });

    test('matching is case-insensitive (input uppercased)', () async {
      await _init();
      expect(Categorizer.instance.categorize('ZOMATO').id, 'food');
    });

    test('matching strips punctuation', () async {
      await _init();
      // "uber!" should still match because "uber" is extracted.
      expect(Categorizer.instance.categorize('uber!').id, 'travel');
    });
  });

  // ── 2. addKeyword() ───────────────────────────────────────────────────────

  group('addKeyword()', () {
    test('returns true for a new keyword', () async {
      await _init();
      expect(Categorizer.instance.addKeyword('food', 'kfc'), isTrue);
    });

    test('added keyword immediately affects categorize()', () async {
      await _init();
      Categorizer.instance.addKeyword('food', 'kfc');
      expect(Categorizer.instance.categorize('kfc bucket').id, 'food');
    });

    test('returns false for a duplicate keyword', () async {
      await _init();
      Categorizer.instance.addKeyword('food', 'kfc');
      expect(Categorizer.instance.addKeyword('food', 'kfc'), isFalse);
    });

    test('returns false for whitespace-only keyword', () async {
      await _init();
      expect(Categorizer.instance.addKeyword('food', '   '), isFalse);
    });

    test('returns false for unknown category id', () async {
      await _init();
      expect(Categorizer.instance.addKeyword('nonexistent_cat', 'kw'), isFalse);
    });

    test('keyword is lowercased before storing', () async {
      await _init();
      Categorizer.instance.addKeyword('food', 'KFC');
      expect(_keywords('food').contains('kfc'), isTrue);
      expect(_keywords('food').contains('KFC'), isFalse);
    });

    test('does not duplicate a bundled keyword', () async {
      await _init();
      // 'zomato' is already in the bundled food list.
      final result = Categorizer.instance.addKeyword('food', 'zomato');
      expect(result, isFalse);
    });
  });

  // ── 3. removeKeyword() ────────────────────────────────────────────────────

  group('removeKeyword()', () {
    test('removes a bundled keyword from the in-memory list', () async {
      await _init();
      expect(_keywords('food').contains('zomato'), isTrue);
      Categorizer.instance.removeKeyword('food', 'zomato');
      expect(_keywords('food').contains('zomato'), isFalse);
    });

    test('removed bundled keyword no longer categorizes correctly', () async {
      await _init();
      Categorizer.instance.removeKeyword('food', 'zomato');
      // 'zomato' alone should fall to misc (no other food keyword matches).
      expect(Categorizer.instance.categorize('zomato').id, 'misc');
    });

    test('removes a previously added custom keyword', () async {
      await _init();
      Categorizer.instance.addKeyword('food', 'kfc');
      Categorizer.instance.removeKeyword('food', 'kfc');
      expect(Categorizer.instance.categorize('kfc').id, 'misc');
    });

    test('returns false for unknown category', () async {
      await _init();
      expect(Categorizer.instance.removeKeyword('ghost', 'kw'), isFalse);
    });

    test('removing a non-existent keyword does not crash', () async {
      await _init();
      // 'helipad' is not a bundled keyword — should be a safe no-op.
      expect(
        () => Categorizer.instance.removeKeyword('travel', 'helipad'),
        returnsNormally,
      );
    });
  });

  // ── 4. Persistence: delta round-trip (simulated restarts) ─────────────────

  group('keyword persistence', () {
    test('custom keyword survives a simulated app restart', () async {
      // --- Session 1 ---
      await _init();
      Categorizer.instance.addKeyword('food', 'kfc');
      // Let the async fire-and-forget _saveKeywords() complete.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // --- Session 2 ---
      _reset();
      await _init(); // loads JSON then replays prefs delta

      expect(
        Categorizer.instance.categorize('kfc bucket').id,
        equals('food'),
        reason: 'Custom keyword "kfc" should survive a restart',
      );
    });

    test('removed bundled keyword persists across restarts', () async {
      // --- Session 1 ---
      await _init();
      Categorizer.instance.removeKeyword('food', 'zomato');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // --- Session 2 ---
      _reset();
      await _init();

      expect(
        Categorizer.instance.categorize('zomato').id,
        equals('misc'),
        reason: 'Removal of bundled keyword "zomato" should persist',
      );
    });

    test('multiple custom keywords across categories survive restart', () async {
      // --- Session 1 ---
      await _init();
      Categorizer.instance.addKeyword('food', 'kfc');
      Categorizer.instance.addKeyword('travel', 'helipad');
      Categorizer.instance.removeKeyword('food', 'zomato');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // --- Session 2 ---
      _reset();
      await _init();

      expect(Categorizer.instance.categorize('kfc').id, 'food');
      expect(Categorizer.instance.categorize('helipad trip').id, 'travel');
      expect(Categorizer.instance.categorize('zomato').id, 'misc');
    });

    test('sessions accumulate: keyword added in S1 + S2 both present in S3',
        () async {
      // --- Session 1 ---
      await _init();
      Categorizer.instance.addKeyword('food', 'kfc');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // --- Session 2 ---
      _reset();
      await _init();
      Categorizer.instance.addKeyword('food', 'mcd');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // --- Session 3 ---
      _reset();
      await _init();
      expect(Categorizer.instance.categorize('kfc').id, 'food');
      expect(Categorizer.instance.categorize('mcd').id, 'food');
    });
  });

  // ── 5. Delta accuracy ─────────────────────────────────────────────────────

  group('delta format in SharedPreferences', () {
    test('delta contains correct added and removed lists', () async {
      await _init();
      Categorizer.instance.addKeyword('travel', 'helipad');
      Categorizer.instance.removeKeyword('travel', 'uber');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('keyword_delta_v1');
      expect(raw, isNotNull, reason: 'Delta should have been saved');

      final delta = jsonDecode(raw!) as Map<String, dynamic>;
      expect(delta.containsKey('travel'), isTrue);

      final travelDelta = delta['travel'] as Map<String, dynamic>;
      final added = List<String>.from(travelDelta['added'] as List);
      final removed = List<String>.from(travelDelta['removed'] as List);

      expect(added, contains('helipad'));
      expect(removed, contains('uber'));
    });

    test('no delta key is written when no mutations happen', () async {
      await _init();
      // No addKeyword / removeKeyword calls.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('keyword_delta_v1'), isNull,
          reason: '_saveKeywords() is only called on mutation');
    });

    test('adding then removing a custom kw leaves it absent from delta',
        () async {
      await _init();
      Categorizer.instance.addKeyword('food', 'testbrand');
      Categorizer.instance.removeKeyword('food', 'testbrand');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('keyword_delta_v1');

      if (raw != null && raw.isNotEmpty) {
        final delta = jsonDecode(raw) as Map<String, dynamic>;
        if (delta.containsKey('food')) {
          final added =
              List<String>.from((delta['food'] as Map)['added'] as List? ?? []);
          expect(added, isNot(contains('testbrand')));
        }
      }
      // If raw is null the test passes — no delta at all is also correct.
    });

    test('delta is sorted alphabetically for deterministic output', () async {
      await _init();
      Categorizer.instance.addKeyword('food', 'zara');
      Categorizer.instance.addKeyword('food', 'alpha');
      Categorizer.instance.addKeyword('food', 'mango');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('keyword_delta_v1')!;
      final delta = jsonDecode(raw) as Map<String, dynamic>;
      final added =
          List<String>.from((delta['food'] as Map)['added'] as List);

      expect(added, equals([...added]..sort()),
          reason: 'Added list should be sorted');
    });
  });
}
