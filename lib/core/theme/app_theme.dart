import 'package:flutter/material.dart';
import '../constants/enums.dart';

/// Color + status palette. Chosen for accessible contrast and a
/// serious "operational software" feel rather than a playful demo look.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B5D77); // deep teal-blue
  static const Color primaryDark = Color(0xFF063C4D);
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A2530);
  static const Color textSecondary = Color(0xFF5B6B79);
  static const Color divider = Color(0xFFE0E5E9);

  static const Color pending = Color(0xFF8A6D00);
  static const Color pendingBg = Color(0xFFFFF3CD);

  static const Color inProgress = Color(0xFF0B5D9A);
  static const Color inProgressBg = Color(0xFFD8ECFF);

  static const Color completed = Color(0xFF1E7B34);
  static const Color completedBg = Color(0xFFDCF5E1);

  static const Color overdue = Color(0xFFB3261E);
  static const Color overdueBg = Color(0xFFFBDAD8);

  static const Color cancelled = Color(0xFF5B6B79);
  static const Color cancelledBg = Color(0xFFE7E9EB);

  static const Color priorityLow = Color(0xFF5B6B79);
  static const Color priorityMedium = Color(0xFF8A6D00);
  static const Color priorityHigh = Color(0xFFB3261E);

  static Color statusColor(TaskStatus status, {bool overdueFlag = false}) {
    if (overdueFlag && status != TaskStatus.completed) return overdue;
    switch (status) {
      case TaskStatus.pending:
        return pending;
      case TaskStatus.inProgress:
        return inProgress;
      case TaskStatus.completed:
        return completed;
      case TaskStatus.cancelled:
        return cancelled;
    }
  }

  static Color statusBgColor(TaskStatus status, {bool overdueFlag = false}) {
    if (overdueFlag && status != TaskStatus.completed) return overdueBg;
    switch (status) {
      case TaskStatus.pending:
        return pendingBg;
      case TaskStatus.inProgress:
        return inProgressBg;
      case TaskStatus.completed:
        return completedBg;
      case TaskStatus.cancelled:
        return cancelledBg;
    }
  }

  static Color priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return priorityLow;
      case TaskPriority.medium:
        return priorityMedium;
      case TaskPriority.high:
        return priorityHigh;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.overdue),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
    );
  }
}
