// lib/data/models/expense.dart
class Expense {
  final int? id;
  final double amount;
  final String description;
  final String category;
  final int timestamp; // Unix epoch in milliseconds

  const Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.timestamp,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      category: map['category'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'timestamp': timestamp,
    };
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  Expense copyWith({
    int? id,
    double? amount,
    String? description,
    String? category,
    int? timestamp,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
