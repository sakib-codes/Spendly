import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/data/models/app_settings_model.dart';
import 'package:spendly/domain/entities/app_settings.dart';

import 'settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() async {
    final db = await AppDatabase.instance;
    final result = await db.query(DatabaseTables.settings);

    if (result.isNotEmpty) {
      return AppSettingsModel.fromMap(result.first);
    }

    // Default fallback if table is empty (though it should be seeded)
    return const AppSettings(
      currency: 'BDT',
      themeMode: 'system',
      firstDayOfMonth: 1,
    );
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    final db = await AppDatabase.instance;
    final model = AppSettingsModel(
      currency: settings.currency,
      themeMode: settings.themeMode,
      firstDayOfMonth: settings.firstDayOfMonth,
    );

    // Assuming a single row of settings with ID 1
    await db.update(
      DatabaseTables.settings,
      model.toMap(),
      where: '${SettingsFields.id} = ?',
      whereArgs: [1],
    );
  }
}
