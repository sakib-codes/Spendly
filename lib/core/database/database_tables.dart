class DatabaseTables {
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String settings = 'settings';
  static const String budgets = 'budgets';
}

class TransactionFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String amount = 'amount'; // Numeric, always positive
  static const String type = 'type'; // 'expense' or 'income'
  static const String categoryId = 'categoryId';
  static const String date = 'date';
  static const String paymentMethod = 'paymentMethod';
  static const String note = 'note';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String isSynced = 'isSynced';
  static const String deletedAt = 'deletedAt';
}

class CategoryFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String icon = 'icon';
  static const String type = 'type'; // 'expense', 'income', or 'both'
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String isSynced = 'isSynced';
  static const String deletedAt = 'deletedAt';
}

class SettingsFields {
  static const String id = 'id'; // single row id
  static const String currency = 'currency';
  static const String themeMode = 'themeMode';
  static const String firstDayOfMonth = 'firstDayOfMonth';
}

class BudgetFields {
  static const String id = 'id';
  static const String categoryId = 'categoryId';
  static const String amount = 'amount';
  static const String month = 'month';
  static const String year = 'year';
  static const String updatedAt = 'updatedAt';
  static const String isSynced = 'isSynced';
  static const String deletedAt = 'deletedAt';
}
