import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackgroundPrimary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightTextPrimary,
      onPrimary: AppColors.lightBackgroundPrimary,
      secondary: AppColors.lightTextSecondary,
      surface: AppColors.lightSurfacePrimary,
      surfaceContainer: AppColors.lightSurfaceGlass,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      error: AppColors.expenseAccent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.lightSurfacePrimary,
      contentTextStyle: TextStyle(color: AppColors.lightTextPrimary),
      actionTextColor: AppColors.incomeAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackgroundPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkTextPrimary,
      onPrimary: AppColors.darkBackgroundPrimary,
      secondary: AppColors.darkTextSecondary,
      surface: AppColors.darkSurfacePrimary,
      surfaceContainer: AppColors.darkSurfaceGlass,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: AppColors.expenseAccent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceSecondary,
      contentTextStyle: TextStyle(color: AppColors.darkTextPrimary),
      actionTextColor: AppColors.incomeAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    useMaterial3: true,
  );
}
