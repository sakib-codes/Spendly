import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_tables.dart';

class DatabaseMigrations {
  static Future<void> createSchemaV1(Database db) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.categories} (
        ${CategoryFields.id} TEXT PRIMARY KEY,
        ${CategoryFields.name} TEXT NOT NULL,
        ${CategoryFields.icon} TEXT NOT NULL,
        ${CategoryFields.type} TEXT NOT NULL,
        ${CategoryFields.createdAt} INTEGER NOT NULL
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.transactions} (
        ${TransactionFields.id} TEXT PRIMARY KEY,
        ${TransactionFields.title} TEXT NOT NULL,
        ${TransactionFields.amount} REAL NOT NULL,
        ${TransactionFields.type} TEXT NOT NULL,
        ${TransactionFields.categoryId} TEXT NOT NULL,
        ${TransactionFields.date} INTEGER NOT NULL,
        ${TransactionFields.paymentMethod} TEXT,
        ${TransactionFields.note} TEXT,
        ${TransactionFields.createdAt} INTEGER NOT NULL,
        ${TransactionFields.updatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${TransactionFields.categoryId}) REFERENCES ${DatabaseTables.categories} (${CategoryFields.id}) ON DELETE CASCADE
      )
    ''');

    // Settings Table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.settings} (
        ${SettingsFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${SettingsFields.currency} TEXT NOT NULL,
        ${SettingsFields.themeMode} TEXT NOT NULL,
        ${SettingsFields.firstDayOfMonth} INTEGER NOT NULL
      )
    ''');

    // Budgets Table (also created in V1 for fresh installs)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.budgets} (
        ${BudgetFields.id} TEXT PRIMARY KEY,
        ${BudgetFields.categoryId} TEXT NOT NULL,
        ${BudgetFields.amount} REAL NOT NULL,
        ${BudgetFields.month} INTEGER NOT NULL,
        ${BudgetFields.year} INTEGER NOT NULL,
        FOREIGN KEY (${BudgetFields.categoryId}) REFERENCES ${DatabaseTables.categories} (${CategoryFields.id}) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultData(db);
  }

  static Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const uuid = Uuid();

    // Default Settings
    await db.insert(DatabaseTables.settings, {
      SettingsFields.currency: 'BDT',
      SettingsFields.themeMode: 'system',
      SettingsFields.firstDayOfMonth: 1,
    });

    // Default Expense Categories
    final expenses = {
      'Food': 'food',
      'Transport': 'transport',
      'Shopping': 'shopping',
      'Bills': 'bills',
      'Entertainment': 'entertainment',
      'Health': 'health',
      'Education': 'education',
      'Other': 'other',
    };
    for (var entry in expenses.entries) {
      await db.insert(DatabaseTables.categories, {
        CategoryFields.id: uuid.v4(),
        CategoryFields.name: entry.key,
        CategoryFields.icon: entry.value,
        CategoryFields.type: 'expense',
        CategoryFields.createdAt: now,
      });
    }

    // Default Income Categories
    final incomes = {
      'Salary': 'salary',
      'Freelance': 'freelance',
      'Business': 'business',
      'Investment': 'investment',
      'Gift': 'gift',
      'Other': 'other',
    };
    for (var entry in incomes.entries) {
      await db.insert(DatabaseTables.categories, {
        CategoryFields.id: uuid.v4(),
        CategoryFields.name: entry.key,
        CategoryFields.icon: entry.value,
        CategoryFields.type: 'income',
        CategoryFields.createdAt: now,
      });
    }
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE ${DatabaseTables.budgets} (
          ${BudgetFields.id} TEXT PRIMARY KEY,
          ${BudgetFields.categoryId} TEXT NOT NULL,
          ${BudgetFields.amount} REAL NOT NULL,
          ${BudgetFields.month} INTEGER NOT NULL,
          ${BudgetFields.year} INTEGER NOT NULL,
          FOREIGN KEY (${BudgetFields.categoryId}) REFERENCES ${DatabaseTables.categories} (${CategoryFields.id}) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Update existing default categories to have proper icons
      final categoryUpdates = {
        'Food': 'food', 'Transport': 'transport', 'Shopping': 'shopping',
        'Bills': 'bills', 'Entertainment': 'entertainment', 'Health': 'health',
        'Education': 'education', 'Salary': 'salary', 'Freelance': 'freelance',
        'Business': 'business', 'Investment': 'investment', 'Gift': 'gift',
        'Other': 'other'
      };
      
      for (var entry in categoryUpdates.entries) {
        await db.update(
          DatabaseTables.categories,
          {CategoryFields.icon: entry.value},
          where: '${CategoryFields.name} = ?',
          whereArgs: [entry.key],
        );
      }
    }
  }
}
