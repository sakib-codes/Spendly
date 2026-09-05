import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats a currency amount smartly:
/// - Whole numbers: ৳60,000
/// - Decimal numbers: ৳6,000.56
String formatBDT(double amount) {
  final hasDecimal = amount != amount.truncateToDouble();
  final formatter = NumberFormat.simpleCurrency(
    name: 'BDT',
    decimalDigits: hasDecimal ? 2 : 0,
  );
  return formatter.format(amount);
}

/// Returns a TextSpan with the decimal part rendered smaller.
/// [baseStyle] is the style for the main number.
/// [decimalStyle] is the style for the decimal portion (smaller).
TextSpan formatBDTRich(double amount, {required TextStyle baseStyle, required TextStyle decimalStyle}) {
  final hasDecimal = amount != amount.truncateToDouble();
  if (hasDecimal) {
    final formatted = NumberFormat.simpleCurrency(name: 'BDT', decimalDigits: 2).format(amount);
    final parts = formatted.split('.');
    if (parts.length == 2) {
      return TextSpan(
        text: '${parts[0]}.',
        style: baseStyle,
        children: [
          TextSpan(text: parts[1], style: decimalStyle),
        ],
      );
    }
  }
  final formatted = NumberFormat.simpleCurrency(name: 'BDT', decimalDigits: 0).format(amount);
  return TextSpan(text: formatted, style: baseStyle);
}
