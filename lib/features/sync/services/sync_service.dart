import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  // Local testing URL for Android emulator
  static const String baseUrl = 'http://10.0.2.2:8000/sync';

  Future<void> push() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();
    if (token == null) return;

    final db = await AppDatabase.instance;

    final unsyncedCategories = await db.query(
      DatabaseTables.categories,
      where: '${CategoryFields.isSynced} = ?',
      whereArgs: [0],
    );

    final unsyncedTransactions = await db.query(
      DatabaseTables.transactions,
      where: '${TransactionFields.isSynced} = ?',
      whereArgs: [0],
    );

    final unsyncedBudgets = await db.query(
      DatabaseTables.budgets,
      where: '${BudgetFields.isSynced} = ?',
      whereArgs: [0],
    );

    if (unsyncedCategories.isEmpty &&
        unsyncedTransactions.isEmpty &&
        unsyncedBudgets.isEmpty) {
      return; // Nothing to sync
    }

    // Add firebase_uid to payload items
    final pushData = {
      'categories':
          unsyncedCategories.map((e) => {...e, 'firebase_uid': user.uid}).toList(),
      'transactions':
          unsyncedTransactions.map((e) => {...e, 'firebase_uid': user.uid}).toList(),
      'budgets':
          unsyncedBudgets.map((e) => {...e, 'firebase_uid': user.uid}).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/push'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(pushData),
      );

      if (response.statusCode == 200) {
        // Mark items as synced locally
        await db.transaction((txn) async {
          for (var c in unsyncedCategories) {
            await txn.update(
              DatabaseTables.categories,
              {CategoryFields.isSynced: 1},
              where: '${CategoryFields.id} = ?',
              whereArgs: [c[CategoryFields.id]],
            );
          }
          for (var t in unsyncedTransactions) {
            await txn.update(
              DatabaseTables.transactions,
              {TransactionFields.isSynced: 1},
              where: '${TransactionFields.id} = ?',
              whereArgs: [t[TransactionFields.id]],
            );
          }
          for (var b in unsyncedBudgets) {
            await txn.update(
              DatabaseTables.budgets,
              {BudgetFields.isSynced: 1},
              where: '${BudgetFields.id} = ?',
              whereArgs: [b[BudgetFields.id]],
            );
          }
        });
      } else {
        print('Sync push failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Sync push error: $e');
    }
  }

  Future<void> pull() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_timestamp');
    
    Uri pullUri = Uri.parse('$baseUrl/pull');
    if (lastSyncStr != null) {
      pullUri = pullUri.replace(queryParameters: {'last_sync_timestamp': lastSyncStr});
    }

    try {
      final response = await http.get(
        pullUri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final db = await AppDatabase.instance;

        await db.transaction((txn) async {
          // Process pulled Categories
          if (data['categories'] != null) {
            for (var item in data['categories']) {
              item.remove('firebase_uid'); // Clean backend-only field
              item[CategoryFields.isSynced] = 1;
              
              if (item[CategoryFields.deletedAt] != null) {
                 await txn.delete(DatabaseTables.categories, where: '${CategoryFields.id} = ?', whereArgs: [item[CategoryFields.id]]);
              } else {
                 await txn.insert(DatabaseTables.categories, Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }

          // Process pulled Transactions
          if (data['transactions'] != null) {
            for (var item in data['transactions']) {
              item.remove('firebase_uid');
              item[TransactionFields.isSynced] = 1;
              
              if (item[TransactionFields.deletedAt] != null) {
                 await txn.delete(DatabaseTables.transactions, where: '${TransactionFields.id} = ?', whereArgs: [item[TransactionFields.id]]);
              } else {
                 await txn.insert(DatabaseTables.transactions, Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }

          // Process pulled Budgets
          if (data['budgets'] != null) {
            for (var item in data['budgets']) {
              item.remove('firebase_uid');
              item[BudgetFields.isSynced] = 1;
              
              if (item[BudgetFields.deletedAt] != null) {
                 await txn.delete(DatabaseTables.budgets, where: '${BudgetFields.id} = ?', whereArgs: [item[BudgetFields.id]]);
              } else {
                 await txn.insert(DatabaseTables.budgets, Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }
        });

        if (data['server_timestamp'] != null) {
          await prefs.setString('last_sync_timestamp', data['server_timestamp']);
        }
      } else {
        print('Sync pull failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Sync pull error: $e');
    }
  }

  Future<void> syncAll() async {
    // Standard offline-first sync pattern: 
    // 1. Push local changes to server.
    // 2. Pull server changes (since last pull) down to local.
    await push();
    await pull();
  }
}
