import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats a currency amount smartly:
/// - Whole numbers: ৳60,000
/// - Decimal numbers: ৳6,000.56
String formatBDT(double amount) {
  final roundedAmount = amount.roundToDouble();
  final formatter = NumberFormat.simpleCurrency(
    name: 'BDT',
    decimalDigits: 0,
  );
  return formatter.format(roundedAmount);
}

/// Returns a TextSpan with the decimal part rendered smaller.
/// [baseStyle] is the style for the main number.
/// [decimalStyle] is the style for the decimal portion (smaller).
TextSpan formatBDTRich(double amount, {required TextStyle baseStyle, required TextStyle decimalStyle}) {
  final roundedAmount = amount.roundToDouble();
  final formatted = NumberFormat.simpleCurrency(name: 'BDT', decimalDigits: 0).format(roundedAmount);
  return TextSpan(text: formatted, style: baseStyle);
}
