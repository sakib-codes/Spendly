import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class AppPreferences {
  final String currency;
  final String firstDayOfMonth;
  final bool useBiometrics;

  AppPreferences({
    this.currency = 'BDT (৳)',
    this.firstDayOfMonth = '1st of Month',
    this.useBiometrics = false,
  });

  AppPreferences copyWith({
    String? currency,
    String? firstDayOfMonth,
    bool? useBiometrics,
  }) {
    return AppPreferences(
      currency: currency ?? this.currency,
      firstDayOfMonth: firstDayOfMonth ?? this.firstDayOfMonth,
      useBiometrics: useBiometrics ?? this.useBiometrics,
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
      useBiometrics: _prefs.getBool('useBiometrics') ?? false,
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
  
  void setUseBiometrics(bool use) {
    _prefs.setBool('useBiometrics', use);
    state = state.copyWith(useBiometrics: use);
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
      PreferencesNotifier.new,
    );
