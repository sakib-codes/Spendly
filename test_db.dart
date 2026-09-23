import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'spendly.db');
  
  if (await File(path).exists()) {
    final db = await openDatabase(path);
    final version = await db.getVersion();
    print('DB Version: $version');
    final cats = await db.query('categories');
    print('Categories count: ${cats.length}');
    for (var cat in cats.take(5)) {
      print('${cat['name']} - ${cat['icon']} - ${cat['type']}');
    }
    
    // Check specific new ones
    final newCats = await db.query('categories', where: 'name IN (?, ?, ?, ?, ?)', whereArgs: ['Home', 'Childcare', 'Fitness', 'Savings', 'Cash']);
    print('New Categories found: ${newCats.length}');
    for (var cat in newCats) {
      print('NEW: ${cat['name']} - ${cat['icon']} - ${cat['type']}');
    }
  } else {
    print('DB not found at $path');
  }
}
