import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database/database_helper.dart';

class ExportService {
  static Future<void> exportExpensesToCsv() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Amount", "Description", "Category", "Date"]);
    
    for (var e in expenses) {
      rows.add([
        e.id,
        e.amount,
        e.description,
        e.category,
        e.dateTime.toIso8601String(),
      ]);
    }
    
    String csv = const ListToCsvConverter().convert(rows);
    
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/expenses_export.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'My Expenses Export',
      ),
    );
  }

  static Future<void> exportExpensesToJson() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    
    final jsonList = expenses.map((e) => e.toMap()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/expenses_export.json';
    final file = File(path);
    await file.writeAsString(jsonString);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'My Expenses Export (JSON)',
      ),
    );
  }

  /// Exports a structured, schema-versioned backup containing all records & metadata.
  static Future<void> exportBackup(String currencyCode) async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    
    final backup = {
      'schema_version': 1,
      'app_id': 'com.stormbreaker.expensetracker',
      'exported_at': DateTime.now().toIso8601String(),
      'currency': currencyCode,
      'expenses': expenses.map((e) => e.toMap()).toList(),
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/antigravity_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(path);
    await file.writeAsString(jsonString);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Antigravity Financial Ledger Backup',
      ),
    );
  }

  /// Imports and restores expenses from a selected JSON backup file.
  /// Returns the number of imported records.
  static Future<int> importBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isEmpty || files.first.path == null) {
      return 0; // user cancelled
    }

    final file = File(files.first.path!);
    final content = await file.readAsString();
    final dynamic data = jsonDecode(content);

    List<dynamic> expenseMaps;
    if (data is Map<String, dynamic> && data.containsKey('expenses')) {
      expenseMaps = data['expenses'] as List<dynamic>;
    } else if (data is List) {
      expenseMaps = data;
    } else {
      throw const FormatException('Invalid backup file structure: missing expenses list.');
    }

    int count = 0;
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final item in expenseMaps) {
        if (item is Map<String, dynamic>) {
          final map = Map<String, dynamic>.from(item)..remove('id');
          if (map.containsKey('amount') &&
              map.containsKey('description') &&
              map.containsKey('category') &&
              map.containsKey('timestamp')) {
            await txn.insert('expenses', map);
            count++;
          }
        }
      }
    });

    return count;
  }
}
