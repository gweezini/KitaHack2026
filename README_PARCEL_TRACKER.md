/// README - University Parcel Tracker App
/// 
/// A comprehensive Flutter application for managing parcel verification,
/// tracking, notifications, and late claim charges at a university.
///
/// FEATURES
/// ========
/// 
/// 1. Student Authentication
///    - Firebase Authentication with university email/password
///    - Email verification
///    - Password reset functionality
///
/// 2. Parcel Management
///    - View all parcels assigned to student
///    - Track parcel status (pending, arrived, claimed, delayed, lost)
///    - Claim parcels with automatic late charge calculation
///    - View parcel arrival dates and deadlines
///
/// 3. Admin Parcel Scanner
///    - Capture parcel images using device camera
///    - Google ML Kit OCR for automatic data extraction
///    - Extract tracking numbers and recipient names
///    - Manual field correction for low-confidence results
///    - Batch scanning capabilities
///
/// 4. Push Notifications
///    - Firebase Cloud Messaging for instant notifications
///    - Parcel arrival notifications
///    - Late claim deadline reminders
///    - Late charge alerts
///
/// 5. Predictive ETA
///    - Estimate delivery times
///    - Predict potential delays
///    - Real-time tracking integration (ready for courier APIs)
///    - Historical delay analysis
///
/// 6. Activity Logging
///    - Complete audit trail of all parcel operations
///    - User action tracking
///    - Admin activity monitoring
///
/// SETUP INSTRUCTIONS
/// ==================
///
/// Prerequisites:
/// - Flutter SDK (version 3.10.8 or higher)
/// - Dart SDK (included with Flutter)
/// - An IDE (Android Studio, VS Code, or Xcode)
/// - Firebase project (create at https://firebase.google.com)
///
/// Step 1: Clone and Setup Project
/// --------------------------------
/// 1. Clone the repository or navigate to the project directory
/// 2. Run: flutter pub get
///
/// Step 2: Firebase Configuration
/// --------------------------------
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add Android app:
///    - Download google-services.json
///    - Place in android/app/
/// 3. Add iOS app:
///    - Download GoogleService-Info.plist
///    - Add to iOS project via Xcode
/// 4. Setup Firebase services:
///    - Enable Authentication (Email/Password)
///    - Create Firestore Database (start in test mode)
///    - Enable Cloud Messaging
///    - Setup App Check (optional but recommended)
///
/// 5. Generate firebase_options.dart:
///    flutter pub global activate flutterfire_cli
///    flutterfire configure
///
/// Step 3: ML Kit Configuration
/// ----------------------------
/// ML Kit is included in google_mlkit_text_recognition dependency.
/// No additional setup needed for Android.
/// For iOS, ensure you have CocoaPods installed.
///
/// Step 4: Permissions Configuration
/// -----------------------------------
/// 
/// Android (android/app/src/main/AndroidManifest.xml):
/// Add the following permissions:
/// 
///   <uses-permission android:name=\"android.permission.CAMERA\" />
///   <uses-permission android:name=\"android.permission.POST_NOTIFICATIONS\" />
///   <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\" />
///
/// iOS (ios/Runner/Info.plist):
/// Add the following keys:
/// 
///   <key>NSCameraUsageDescription</key>
///   <string>This app needs camera access to scan parcels</string>
///   <key>NSLocationWhenInUseUsageDescription</key>
///   <string>This app needs location access for parcel tracking</string>
///
/// Step 5: Run the App
/// ------------------
/// flutter run
///
/// IMPORTANT CUSTOMIZATION POINTS
/// ===============================
///
/// 1. University Email Domain (lib/services/firebase_auth_service.dart)
///    - Update _isValidUniversityEmail() with your institution's domains
///
/// 2. Late Charge Configuration (lib/models/parcel_model.dart)
///    - Update gracePeriodDays and chargePerDay values
///
/// 3. App Constants (lib/constants.dart)
///    - Update university name, email domains, and other settings
///
/// 4. UI Theme (lib/main.dart)
///    - Customize colors to match your institution's branding
///
/// 5. OCR Pattern Matching (lib/services/ml_kit_ocr_service.dart)
///    - Update regex patterns for your parcel label formats
///
/// PROJECT STRUCTURE
/// =================
///
/// lib/
/// ├── main.dart                          # App entry point and initialization
/// ├── firebase_options.dart              # Firebase configuration (generated)
/// ├── constants.dart                     # App-wide constants
/// ├── utils.dart                         # Utility functions and helpers
/// │
/// ├── models/
/// │   ├── user_model.dart               # User data model
/// │   ├── parcel_model.dart             # Parcel data model
/// │   ├── log_model.dart                # Activity log model
/// │   └── ocr_result_model.dart         # OCR results model
/// │
/// ├── services/
/// │   ├── firebase_auth_service.dart    # Authentication service
/// │   ├── firestore_service.dart        # Firestore database service
/// │   ├── ml_kit_ocr_service.dart       # ML Kit OCR service
/// │   ├── notification_service.dart     # Push notification service
/// │   └── eta_service.dart              # ETA prediction service
/// │
/// ├── screens/
/// │   ├── login_screen.dart             # Student login
/// │   ├── student_home_screen.dart      # Student parcel list
/// │   ├── admin_scanner_screen.dart     # Admin parcel scanner
/// │   └── parcel_detail_screen.dart     # Parcel detail view
/// │
/// android/                               # Android platform code
/// ├── app/
/// │   └── google-services.json           # Firebase Android config
/// └── ...
///
/// ios/                                   # iOS platform code
/// ├── Runner/
/// │   └── GoogleService-Info.plist      # Firebase iOS config
/// └── ...
///
/// NEXT STEPS FOR DEVELOPMENT
/// ============================
///
/// TODO Items Throughout the Codebase:
/// 1. Complete all Firebase service integrations
/// 2. Implement missing payment processing for late charges
/// 3. Add social login options (Google sign-in, Microsoft account)
/// 4. Integrate with actual courier APIs (UPS, FedEx, DHL, etc.)
/// 5. Implement advanced ETA predictive models using ML
/// 6. Add support for multiple languages
/// 7. Implement comprehensive error tracking and analytics
/// 8. Add advanced security features (biometric login, encryption)
/// 9. Create admin dashboard for parcel management
/// 10. Implement batch notification sending
///
/// SECURITY CONSIDERATIONS
/// =======================
///
/// 1. Always use Firebase security rules to protect user data
/// 2. Implement proper email verification for student accounts
/// 3. Use HTTPS for all API communications
/// 4. Validate and sanitize all user inputs
/// 5. Store sensitive data securely
/// 6. Implement rate limiting for authentication attempts
/// 7. Use Firebase App Check for additional security
/// 8. Regularly audit activity logs for suspicious behavior
///
/// TESTING
/// =======
///
/// Run unit tests:
/// flutter test
///
/// Run integration tests:
/// flutter test integration_test
///
/// Build release APK (Android):
/// flutter build apk --release
///
/// Build release IPA (iOS):
/// flutter build ios --release
///
/// TROUBLESHOOTING
/// ===============
///
/// Firebase not initializing:
/// - Ensure firebase_options.dart is properly generated
/// - Check internet connection
/// - Verify Firebase project is active
///
/// ML Kit OCR not working:
/// - Check camera permissions are granted
/// - Ensure image quality is acceptable
/// - Test with different parcel label formats
///
/// Push notifications not received:
/// - Check FCM token is being saved to Firestore
/// - Verify push notification payload format
/// - Check Firebase Cloud Messaging is enabled
///
/// SUPPORT & RESOURCES
/// ===================
///
/// Documentation:
/// - Flutter: https://docs.flutter.dev
/// - Firebase: https://firebase.google.com/docs
/// - ML Kit: https://developers.google.com/ml-kit
///
/// Community:
/// - Flutter Community: https://flutter.dev/community
/// - Firebase Support: https://firebase.google.com/support
///
/// For issues or questions about this app skeleton, refer to the inline
/// TODO comments throughout the codebase for specific implementation areas.
