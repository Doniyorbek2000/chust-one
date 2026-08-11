import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.navy900,
      primaryColor: AppColors.primaryLime,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLime,
        secondary: AppColors.primaryLimeDark,
        surface: AppColors.navy800,
        onPrimary: AppColors.navy900,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.error,
      ),
      cardTheme: CardThemeData(
        color: AppColors.navy800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy900,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navy900,
        selectedItemColor: AppColors.primaryLime,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}
