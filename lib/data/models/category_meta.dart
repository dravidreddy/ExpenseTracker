// lib/data/models/category_meta.dart
import 'dart:ui';

class CategoryMeta {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final List<String> keywords;
  final bool isCustom;

  const CategoryMeta({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.keywords,
    this.isCustom = false,
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
      isCustom: json['isCustom'] as bool? ?? false,
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
      'isCustom': isCustom,
    };
  }

  CategoryMeta copyWith({
    String? id,
    String? label,
    String? emoji,
    Color? color,
    List<String>? keywords,
    bool? isCustom,
  }) {
    return CategoryMeta(
      id: id ?? this.id,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      keywords: keywords ?? this.keywords,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
