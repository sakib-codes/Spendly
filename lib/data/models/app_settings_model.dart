import '../../core/database/database_tables.dart';
import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.currency,
    required super.themeMode,
    required super.firstDayOfMonth,
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      currency: map[SettingsFields.currency] as String,
      themeMode: map[SettingsFields.themeMode] as String,
      firstDayOfMonth: map[SettingsFields.firstDayOfMonth] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      SettingsFields.currency: currency,
      SettingsFields.themeMode: themeMode,
      SettingsFields.firstDayOfMonth: firstDayOfMonth,
    };
  }
}
