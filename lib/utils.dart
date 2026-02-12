/// Utility Functions and Helpers

import 'package:intl/intl.dart';

/// Date formatting utilities
class DateUtils {
  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date and time for display
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  /// Check if date is past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Get days remaining until deadline
  static int daysUntil(DateTime deadline) {
    return deadline.difference(DateTime.now()).inDays;
  }

  /// Get days since date
  static int daysSince(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }
}

/// Validation utilities
class Validators {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate tracking number format
  /// TODO: Customize based on your courier formats
  static bool isValidTrackingNumber(String trackingNumber) {
    return trackingNumber.length >= 8 && trackingNumber.length <= 15;
  }

  /// Validate student ID format
  /// TODO: Customize based on your institution's ID format
  static bool isValidStudentId(String studentId) {
    // Example: Allow alphanumeric, 6-10 characters
    final studentIdRegex = RegExp(r'^[A-Z0-9]{6,10}$');
    return studentIdRegex.hasMatch(studentId);
  }
}

/// String utilities
class StringUtils {
  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Format tracking number for display (add spaces/hyphens)
  /// TODO: Implement based on parcel format
  static String formatTrackingNumber(String trackingNumber) {
    return trackingNumber.toUpperCase();
  }
}

/// Currency utilities
class CurrencyUtils {
  /// Format currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Parse currency string
  static double? parseCurrency(String amount) {
    try {
      return double.parse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      return null;
    }
  }
}

/// Logging utilities
class AppLogger {
  static const String _logPrefix = '[ParcelTracker]';

  /// Log info
  static void info(String message) {
    print('$_logPrefix [INFO] $message');
  }

  /// Log warning
  static void warning(String message) {
    print('$_logPrefix [WARNING] $message');
  }

  /// Log error
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('$_logPrefix [ERROR] $message');
    if (error != null) print('$_logPrefix Error: $error');
    if (stackTrace != null) print('$_logPrefix StackTrace: $stackTrace');
  }

  /// Log debug
  static void debug(String message) {
    print('$_logPrefix [DEBUG] $message');
  }
}
