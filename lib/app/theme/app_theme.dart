import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackgroundPrimary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightTextPrimary,
      secondary: AppColors.lightTextSecondary,
      surface: AppColors.lightSurfacePrimary,
      error: AppColors.expenseAccent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.lightSurfacePrimary,
      contentTextStyle: TextStyle(color: AppColors.lightTextPrimary),
      actionTextColor: AppColors.incomeAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackgroundPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkTextPrimary,
      secondary: AppColors.darkTextSecondary,
      surface: AppColors.darkSurfacePrimary,
      error: AppColors.expenseAccent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceSecondary,
      contentTextStyle: TextStyle(color: AppColors.darkTextPrimary),
      actionTextColor: AppColors.incomeAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    useMaterial3: true,
  );
}
