// lib/data/models/category_meta.dart
import 'dart:ui';

class CategoryMeta {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final List<String> keywords;

  const CategoryMeta({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.keywords,
  });

  factory CategoryMeta.fromJson(Map<String, dynamic> json) {
    final hexColor = (json['color'] as String).replaceFirst('#', '');
    final color = Color(int.parse('FF$hexColor', radix: 16));
    return CategoryMeta(
      id: json['id'] as String,
      label: json['label'] as String,
      emoji: json['emoji'] as String,
      color: color,
      keywords: List<String>.from(json['keywords'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'emoji': emoji,
      'color':
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'keywords': keywords,
    };
  }

  CategoryMeta copyWith({List<String>? keywords}) {
    return CategoryMeta(
      id: id,
      label: label,
      emoji: emoji,
      color: color,
      keywords: keywords ?? this.keywords,
    );
  }
}
