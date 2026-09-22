import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class AppPreferences {
  final String currency;
  final String firstDayOfMonth;

  AppPreferences({
    this.currency = 'BDT (৳)',
    this.firstDayOfMonth = '1st of Month',
  });

  AppPreferences copyWith({String? currency, String? firstDayOfMonth}) {
    return AppPreferences(
      currency: currency ?? this.currency,
      firstDayOfMonth: firstDayOfMonth ?? this.firstDayOfMonth,
    );
  }
}

class PreferencesNotifier extends Notifier<AppPreferences> {
  late SharedPreferences _prefs;

  @override
  AppPreferences build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return AppPreferences(
      currency: _prefs.getString('currency') ?? 'BDT (৳)',
      firstDayOfMonth: _prefs.getString('firstDayOfMonth') ?? '1st of Month',
    );
  }

  void setCurrency(String currency) {
    _prefs.setString('currency', currency);
    state = state.copyWith(currency: currency);
  }

  void setFirstDayOfMonth(String day) {
    _prefs.setString('firstDayOfMonth', day);
    state = state.copyWith(firstDayOfMonth: day);
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
      PreferencesNotifier.new,
    );
