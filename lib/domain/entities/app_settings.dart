import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String currency;
  final String themeMode;
  final int firstDayOfMonth;

  const AppSettings({
    required this.currency,
    required this.themeMode,
    required this.firstDayOfMonth,
  });

  @override
  List<Object?> get props => [currency, themeMode, firstDayOfMonth];
}
