/// Firebase Configuration Options
/// TODO: After Firebase setup, run: flutterfire configure
/// This will auto-generate the platform-specific configurations below.
/// 
/// For now, this includes placeholder web configuration.
/// Android: requires google-services.json in android/app/
/// iOS: requires GoogleService-Info.plist in ios/Runner/

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform is not supported for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform is not supported for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform is not supported for Linux.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform is not supported for Fuchsia.',
        );
    }
  }

  /// Web Firebase configuration (placeholder - update after flutterfire configure)
  /// TODO: Replace these with your actual Firebase web credentials
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDWF-1234567890abcdefghijklmnopqr',
    appId: '1:1234567890:web:abcdef1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'parcel-tracker-demo',
    authDomain: 'parcel-tracker-demo.firebaseapp.com',
    databaseURL: 'https://parcel-tracker-demo.firebaseio.com',
    storageBucket: 'parcel-tracker-demo.appspot.com',
    measurementId: 'G-ABCDEF1234',
  );

  /// Android Firebase configuration (placeholder)
  /// TODO: After adding Android app in Firebase Console, run: flutterfire configure
  /// This will auto-generate the config from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWF-1234567890abcdefghijklmnopqr',
    appId: '1:1234567890:android:abcdef1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'parcel-tracker-demo',
    storageBucket: 'parcel-tracker-demo.appspot.com',
  );

  /// iOS Firebase configuration (placeholder)
  /// TODO: After adding iOS app in Firebase Console, run: flutterfire configure
  /// GoogleService-Info.plist should already be in ios/Runner/
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWF-1234567890abcdefghijklmnopqr',
    appId: '1:1234567890:ios:abcdef1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'parcel-tracker-demo',
    storageBucket: 'parcel-tracker-demo.appspot.com',
    iosBundleId: 'com.example.test1',
  );
}
