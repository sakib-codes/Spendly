import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  // Live Render backend URL
  static const String baseUrl = 'https://spendly-o4hk.onrender.com';

  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  Future<int> refreshPendingCount() async {
    try {
      final db = await AppDatabase.instance;
      final catCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseTables.categories} WHERE ${CategoryFields.isSynced} = 0',
      )) ?? 0;
      final txnCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseTables.transactions} WHERE ${TransactionFields.isSynced} = 0',
      )) ?? 0;
      final budCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseTables.budgets} WHERE ${BudgetFields.isSynced} = 0',
      )) ?? 0;
      final total = catCount + txnCount + budCount;
      pendingCountNotifier.value = total;
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_successful_sync_time') ??
        prefs.getString('last_sync_timestamp');
    if (timeStr == null || timeStr.isEmpty) return null;
    return DateTime.tryParse(timeStr);
  }

  String _formatTimestamp(dynamic epochMs) {
    if (epochMs == null || epochMs == 0) {
      return DateTime.now().toUtc().toIso8601String();
    }
    return DateTime.fromMillisecondsSinceEpoch(epochMs as int, isUtc: true)
        .toIso8601String();
  }

  String? _formatNullableTimestamp(dynamic epochMs) {
    if (epochMs == null || epochMs == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(epochMs as int, isUtc: true)
        .toIso8601String();
  }

  int _parseTimestamp(dynamic isoStr) {
    if (isoStr == null) return DateTime.now().millisecondsSinceEpoch;
    if (isoStr is int) return isoStr;
    return DateTime.parse(isoStr.toString()).millisecondsSinceEpoch;
  }

  int? _parseNullableTimestamp(dynamic isoStr) {
    if (isoStr == null) return null;
    if (isoStr is int) return isoStr;
    return DateTime.parse(isoStr.toString()).millisecondsSinceEpoch;
  }

  /// Sync user profile to backend
  Future<void> syncUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firebase_uid': user.uid,
          'email': user.email ?? '',
          'full_name': user.displayName ?? '',
        }),
      );

      if (kDebugMode) {
        debugPrint('Sync user response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync user error: $e');
      }
    }
  }

  /// Pushes local unsynced changes to Render backend
  Future<bool> push() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken();
    if (token == null) return false;

    isSyncingNotifier.value = true;
    try {
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
        return true; // Nothing to sync
      }

    // Format categories with ISO dates and snake_case backend keys
    final categoriesPayload = unsyncedCategories.map((c) {
      return {
        'id': c[CategoryFields.id],
        'firebase_uid': user.uid,
        'name': c[CategoryFields.name],
        'icon': c[CategoryFields.icon],
        'type': c[CategoryFields.type],
        'created_at': _formatTimestamp(c[CategoryFields.createdAt]),
        'updated_at': _formatTimestamp(c[CategoryFields.updatedAt]),
        'deleted_at': _formatNullableTimestamp(c[CategoryFields.deletedAt]),
      };
    }).toList();

    // Format transactions with ISO dates and snake_case backend keys
    final transactionsPayload = unsyncedTransactions.map((t) {
      return {
        'id': t[TransactionFields.id],
        'firebase_uid': user.uid,
        'category_id': t[TransactionFields.categoryId],
        'title': t[TransactionFields.title],
        'amount': (t[TransactionFields.amount] as num).toDouble(),
        'type': t[TransactionFields.type],
        'date': _formatTimestamp(t[TransactionFields.date]),
        'payment_method': (t[TransactionFields.paymentMethod] as String?) ?? 'Cash',
        'note': t[TransactionFields.note] as String?,
        'created_at': _formatTimestamp(t[TransactionFields.createdAt]),
        'updated_at': _formatTimestamp(t[TransactionFields.updatedAt]),
        'deleted_at': _formatNullableTimestamp(t[TransactionFields.deletedAt]),
      };
    }).toList();

    // Format budgets with ISO month and snake_case backend keys
    final budgetsPayload = unsyncedBudgets.map((b) {
      final month = b[BudgetFields.month] as int;
      final year = b[BudgetFields.year] as int;
      final monthDateTime = DateTime.utc(year, month, 1);

      return {
        'id': b[BudgetFields.id],
        'firebase_uid': user.uid,
        'category_id': b[BudgetFields.categoryId],
        'amount': (b[BudgetFields.amount] as num).toDouble(),
        'month': monthDateTime.toIso8601String(),
        'created_at': _formatTimestamp(b[BudgetFields.updatedAt]),
        'updated_at': _formatTimestamp(b[BudgetFields.updatedAt]),
        'deleted_at': _formatNullableTimestamp(b[BudgetFields.deletedAt]),
      };
    }).toList();

    final pushData = {
      'categories': categoriesPayload,
      'transactions': transactionsPayload,
      'budgets': budgetsPayload,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/sync/push'),
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
        if (kDebugMode) {
          debugPrint(
            'Sync push succeeded: ${categoriesPayload.length} categories, '
            '${transactionsPayload.length} txns, ${budgetsPayload.length} budgets',
          );
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_successful_sync_time',
          DateTime.now().toUtc().toIso8601String(),
        );
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Sync push failed: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync push error: $e');
      }
      return false;
    } finally {
      isSyncingNotifier.value = false;
      await refreshPendingCount();
    }
  }

  /// Pulls remote updates from Render backend and merges into local SQLite
  Future<bool> pull() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken();
    if (token == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_timestamp');

    Uri pullUri = Uri.parse('$baseUrl/sync/pull');
    if (lastSyncStr != null && lastSyncStr.isNotEmpty) {
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final db = await AppDatabase.instance;

        await db.transaction((txn) async {
          // Process pulled Categories
          if (data['categories'] is List) {
            for (var item in (data['categories'] as List)) {
              final id = item['id'] as String;
              final deletedAt = _parseNullableTimestamp(item['deleted_at']);

              if (deletedAt != null) {
                await txn.delete(
                  DatabaseTables.categories,
                  where: '${CategoryFields.id} = ?',
                  whereArgs: [id],
                );
              } else {
                await txn.insert(
                  DatabaseTables.categories,
                  {
                    CategoryFields.id: id,
                    CategoryFields.name: item['name'],
                    CategoryFields.icon: item['icon'],
                    CategoryFields.type: item['type'],
                    CategoryFields.createdAt: _parseTimestamp(item['created_at']),
                    CategoryFields.updatedAt: _parseTimestamp(item['updated_at']),
                    CategoryFields.isSynced: 1,
                    CategoryFields.deletedAt: null,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }

          // Process pulled Transactions
          if (data['transactions'] is List) {
            for (var item in (data['transactions'] as List)) {
              final id = item['id'] as String;
              final deletedAt = _parseNullableTimestamp(item['deleted_at']);

              if (deletedAt != null) {
                await txn.delete(
                  DatabaseTables.transactions,
                  where: '${TransactionFields.id} = ?',
                  whereArgs: [id],
                );
              } else {
                await txn.insert(
                  DatabaseTables.transactions,
                  {
                    TransactionFields.id: id,
                    TransactionFields.title: item['title'],
                    TransactionFields.amount: (item['amount'] as num).toDouble(),
                    TransactionFields.type: item['type'],
                    TransactionFields.categoryId:
                        item['category_id'] ?? item['categoryId'],
                    TransactionFields.date: _parseTimestamp(item['date']),
                    TransactionFields.paymentMethod:
                        item['payment_method'] ?? item['paymentMethod'] ?? 'Cash',
                    TransactionFields.note: item['note'],
                    TransactionFields.createdAt:
                        _parseTimestamp(item['created_at']),
                    TransactionFields.updatedAt:
                        _parseTimestamp(item['updated_at']),
                    TransactionFields.isSynced: 1,
                    TransactionFields.deletedAt: null,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }

          // Process pulled Budgets
          if (data['budgets'] is List) {
            for (var item in (data['budgets'] as List)) {
              final id = item['id'] as String;
              final deletedAt = _parseNullableTimestamp(item['deleted_at']);

              if (deletedAt != null) {
                await txn.delete(
                  DatabaseTables.budgets,
                  where: '${BudgetFields.id} = ?',
                  whereArgs: [id],
                );
              } else {
                final monthDate = DateTime.parse(item['month'] as String);

                await txn.insert(
                  DatabaseTables.budgets,
                  {
                    BudgetFields.id: id,
                    BudgetFields.categoryId:
                        item['category_id'] ?? item['categoryId'],
                    BudgetFields.amount: (item['amount'] as num).toDouble(),
                    BudgetFields.month: monthDate.month,
                    BudgetFields.year: monthDate.year,
                    BudgetFields.updatedAt:
                        _parseTimestamp(item['updated_at']),
                    BudgetFields.isSynced: 1,
                    BudgetFields.deletedAt: null,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }
        });

        if (data['server_timestamp'] != null) {
          await prefs.setString(
            'last_sync_timestamp',
            data['server_timestamp'].toString(),
          );
        }
        await prefs.setString(
          'last_successful_sync_time',
          DateTime.now().toUtc().toIso8601String(),
        );

        if (kDebugMode) {
          debugPrint('Sync pull succeeded.');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Sync pull failed: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync pull error: $e');
      }
      return false;
    } finally {
      await refreshPendingCount();
    }
  }

  Future<bool> syncAll() async {
    isSyncingNotifier.value = true;
    try {
      await syncUser();
      final pushed = await push();
      if (pushed) {
        final pulled = await pull();
        if (pulled) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_successful_sync_time',
            DateTime.now().toUtc().toIso8601String(),
          );
          return true;
        }
      }
      return false;
    } finally {
      isSyncingNotifier.value = false;
      await refreshPendingCount();
    }
  }
}
