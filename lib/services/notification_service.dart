/// Firebase Cloud Messaging (Push Notification) Service
/// Handles push notifications for parcel arrivals, updates, and alerts

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/parcel_model.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize Firebase Messaging
  /// Note: Some features may not be available on web platform
  Future<void> initializeNotifications() async {
    try {
      // Skip on web - FCM web has limited support
      if (kIsWeb) {
        print('FCM notifications limited on web platform');
        return;
      }

      // Request notification permission (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      // Get FCM token for this device
      final fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $fcmToken');

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundNotification(message);
      });

      // Handle background notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      // Continue anyway - notifications are optional
    }
  }

  /// Get FCM token for current device
  Future<String?> getFCMToken() async {
    try {
      if (kIsWeb) return null;
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore
  void saveFCMTokenToDatabase(String userId, String token) {
    print('TODO: Save FCM token $token for user $userId to Firestore');
  }

  /// Send notification when parcel arrives
  Future<void> notifyParcelArrival(Parcel parcel, String recipientFCMToken) async {
    try {
      final notificationData = {
        'title': 'Parcel Arrived!',
        'body':
            'Your parcel from ${parcel.senderInfo ?? "a sender"} has arrived at the reception.',
        'parcelId': parcel.parcelId,
        'trackingNumber': parcel.trackingNumber,
        'action': 'open_parcel_detail',
      };

      print('TODO: Send notification to token $recipientFCMToken');
      print('Notification data: $notificationData');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Send reminder notification for unclaimed parcels
  Future<void> sendUnclaimedParcelReminder(
      Parcel parcel, String recipientFCMToken) async {
    try {
      final daysOverdue = _calculateDaysOverdue(parcel.dateReceived);

      final notificationData = {
        'title': 'Claim Your Parcel',
        'body':
            'Your parcel has been waiting for $daysOverdue days. Please claim it to avoid late charges.',
        'parcelId': parcel.parcelId,
        'trackingNumber': parcel.trackingNumber,
        'action': 'open_claim_page',
      };

      print('TODO: Send reminder notification');
      print('Notification data: $notificationData');
    } catch (e) {
      print('Error sending reminder: $e');
    }
  }

  /// Send notification for late claim charges
  Future<void> sendLateChalgeNotification(
      Parcel parcel, double charge, String recipientFCMToken) async {
    try {
      // TODO: Implement notification sending with payment gateway
      // final notificationData = {
      //   'title': 'Late Claim Charge Applied',
      //   'body': 'A late claim charge of \$$charge has been applied to your parcel.',
      //   'parcelId': parcel.parcelId,
      //   'trackingNumber': parcel.trackingNumber,
      //   'action': 'open_payment_page',
      // };

      print('TODO: Send late charge notification');
    } catch (e) {
      print('Error sending late charge notification: $e');
    }
  }

  /// Handle foreground notifications (app is open)
  void _handleForegroundNotification(RemoteMessage message) {
    print('Foreground notification received: ${message.notification?.title}');
  }

  /// Handle notification tap (user clicks on notification)
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
  }

  /// Calculate days overdue since parcel arrival
  int _calculateDaysOverdue(DateTime dateReceived) {
    final gracePeriod = 7;
    final daysElapsed = DateTime.now().difference(dateReceived).inDays;
    return (daysElapsed - gracePeriod).clamp(0, 999);
  }

  /// Unsubscribe from all notifications (logout)
  Future<void> unsubscribeFromNotifications() async {
    try {
      print('TODO: Clean up notifications on logout');
    } catch (e) {
      print('Error unsubscribing: $e');
    }
  }
}
