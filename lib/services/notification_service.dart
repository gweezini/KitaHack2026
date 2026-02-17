import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks for parcels that are 1 day away from being overdue (Day 3)
  /// and sends a notification to the student.
  /// Returns the number of notifications sent.
  Future<int> checkAndSendOverdueReminders(BuildContext context) async {
    int notificationsSent = 0;
    
    try {
      // 1. Get all parcels that are 'Pending Pickup'
      final QuerySnapshot parcelSnapshot = await _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'Pending Pickup')
          .get();

      final WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();

      for (var doc in parcelSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? type = data['type'] as String?;
        final Timestamp? arrivalDate = data['arrivalDate'] as Timestamp?;
        final String? studentId = data['studentId'] as String?;
        final String? trackingNumber = data['trackingNumber'] as String?;
        
        // Skip if vital data is missing
        if (arrivalDate == null || studentId == null || type == null) continue;

        // Skip if reminder already sent
        if (data['reminderSent'] == true) continue;

        final int daysUncollected = now.difference(arrivalDate.toDate()).inDays;
        final String parcelType = type.toLowerCase();
        
        bool shouldNotify = false;
        String message = "";
        
        // Logic for Parcels: Overdue after 3 days. Notify on Day 3.
        // Logic for others (documents): Overdue after 14 days. Notify on Day 13 or 14? 
        // User specifically asked for "parcel", but let's handle standard logic:
        // Standard Parcel: Free for 3 days. Charge on Day 4. Reminder on Day 3.
        // Non-Parcel: Free for 14 days. Charge on Day 15. Reminder on Day 14.
        
        final nonParcelTypes = ['letter', 'card', 'document', 'book'];

        if (nonParcelTypes.contains(parcelType)) {
             if (daysUncollected == 14) {
               shouldNotify = true;
               message = "Urgent: Your $type ($trackingNumber) will be charged overdue fees tomorrow!";
             }
        } else {
            // Standard Parcel
            if (daysUncollected == 3) {
               shouldNotify = true;
               message = "Urgent: Your parcel ($trackingNumber) will be charged overdue fees tomorrow!";
            }
        }

        if (shouldNotify) {
          // Add notification
          final notifRef = _firestore.collection('notifications').doc();
          batch.set(notifRef, {
            'studentId': studentId,
            'title': 'Overdue Warning',
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'relatedParcelId': doc.id,
          });

          // Mark parcel as reminded
          batch.update(doc.reference, {'reminderSent': true});
          
          notificationsSent++;
        }
      }

      // Commit all changes
      if (notificationsSent > 0) {
        await batch.commit();
      }
      
      return notificationsSent;

    } catch (e) {
      print("Error sending reminders: $e");
      rethrow; 
    }
  }
}
