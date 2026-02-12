/// App Constants
/// Centralized location for all app-wide constants and configuration

/// Firebase Configuration
class FirebaseConfig {
  // TODO: Update these with your actual Firebase configuration
  static const String projectId = 'your-project-id';
  static const String apiKey = 'your-api-key';
  
  // Collections
  static const String usersCollection = 'users';
  static const String parcelsCollection = 'parcels';
  static const String logsCollection = 'activity_logs';
}


/// App Configuration
class AppConfig {
  // Grace period before late charges apply (in days)
  static const int claimGracePeriodDays = 7;
  
  // Late claim charge calculation
  static const double lateChargePerDay = 5.0;
  
  // University settings
  static const String universityName = 'Your University';
  static const String universityEmailDomain = '@university.edu';
  
  // OCR confidence thresholds
  static const double minOCRConfidence = 0.75;
  static const double acceptableOCRConfidence = 0.85;
  
  // Map and location
  static const double defaultMapZoom = 15.0;
  
  // Notification settings
  static const int reminderDaysBeforeDeadline = 3;
}

/// API Endpoints (for future courier integrations)
class APIEndpoints {
  static const String baseUrl = 'https://api.example.com';
  
  // TODO: Add courier service API endpoints
  // Example: UPS, FedEx, DHL, etc.
  static const String courierTracking = '$baseUrl/tracking';
  static const String etaEstimation = '$baseUrl/eta';
}

/// Asset Paths
class AssetPaths {
  static const String imagesPath = 'assets/images';
  static const String iconsPath = 'assets/icons';
  
  // App logo
  static const String appLogo = '$imagesPath/app_logo.png';
}

/// UI Constants
class UIConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
}

/// Error Messages
class ErrorMessages {
  static const String networkError = 'Network connection error. Please try again.';
  static const String firebaseError = 'An error occurred. Please try again later.';
  static const String ocrError = 'Failed to read parcel information. Please try again.';
  static const String invalidEmail = 'Please enter a valid university email.';
  static const String weakPassword = 'Password must be at least 6 characters long.';
  static const String parcelNotFound = 'Parcel not found in the system.';
}

/// Success Messages
class SuccessMessages {
  static const String parcelClaimed = 'Parcel claimed successfully!';
  static const String parcelScanned = 'Parcel scanned successfully!';
  static const String loginSuccess = 'Login successful!';
}
