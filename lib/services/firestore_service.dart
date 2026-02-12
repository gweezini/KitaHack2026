/// Firestore Database Service
/// Handles all Firestore database operations for parcels, users, and activity logs

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parcel_model.dart';
import '../models/user_model.dart';
import '../models/log_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PARCEL OPERATIONS ====================

  /// Fetch all parcels for a specific student
  /// TODO: Implement pagination for large datasets
  Future<List<Parcel>> getParcelsByStudentId(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('parcels')
          .where('recipientStudentId', isEqualTo: studentId)
          .orderBy('dateReceived', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Parcel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch parcel by tracking number
  /// TODO: Implement caching for frequently accessed parcels
  Future<Parcel?> getParcelByTrackingNumber(String trackingNumber) async {
    try {
      final snapshot = await _firestore
          .collection('parcels')
          .where('trackingNumber', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Parcel.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch parcel by ID
  Future<Parcel?> getParcelById(String parcelId) async {
    try {
      final doc = await _firestore.collection('parcels').doc(parcelId).get();
      if (!doc.exists) return null;
      return Parcel.fromFirestore(doc.data() ?? {}, parcelId);
    } catch (e) {
      rethrow;
    }
  }

  /// Add new parcel to database (Admin function)
  /// TODO: 
  /// - Validate tracking number uniqueness
  /// - Send notification to recipient
  /// - Audit log entry
  Future<String> addParcel(Parcel parcel) async {
    try {
      final docRef = await _firestore.collection('parcels').add(parcel.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update parcel status
  /// TODO: Implement status validation (ensure valid state transitions)
  Future<void> updateParcelStatus({
    required String parcelId,
    required String newStatus,
    DateTime? dateClaimedBy,
    double? lateCharge,
  }) async {
    try {
      await _firestore.collection('parcels').doc(parcelId).update({
        'status': newStatus,
        if (dateClaimedBy != null) 'dateClaimedBy': dateClaimedBy,
        if (lateCharge != null) 'lateClaimCharge': lateCharge,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update parcel notification status
  Future<void> markNotificationSent(String parcelId) async {
    try {
      await _firestore.collection('parcels').doc(parcelId).update({
        'notificationSent': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get all parcels pending claim
  /// TODO: Implement filtering for various parcel states
  Future<List<Parcel>> getPendingParcels() async {
    try {
      final snapshot = await _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'arrived')
          .orderBy('dateReceived', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Parcel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get parcels with late claim charges
  /// TODO: Implement calculation of late charges based on date
  Future<List<Parcel>> getDelayedParcels() async {
    try {
      final snapshot = await _firestore
          .collection('parcels')
          .where('status', isEqualTo: 'arrived')
          .get();

      final parcels = snapshot.docs
          .map((doc) => Parcel.fromFirestore(doc.data(), doc.id))
          .toList();

      return parcels.where((p) => p.isClaimLate()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Fetch user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc.data() ?? {}, userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user by student ID
  Future<User?> getUserByStudentId(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return User.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUser(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Verify user email in database
  Future<void> verifyUserEmail(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isVerified': true});
    } catch (e) {
      rethrow;
    }
  }

  // ==================== ACTIVITY LOG OPERATIONS ====================

  /// Add activity log entry
  /// TODO: Implement batch logging for performance
  Future<void> addActivityLog(ActivityLog log) async {
    try {
      await _firestore.collection('activity_logs').add(log.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Get activity logs for a user
  Future<List<ActivityLog>> getUserActivityLogs(String userId,
      {int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get activity logs for a parcel
  Future<List<ActivityLog>> getParcelActivityLogs(String parcelId) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('parcelId', isEqualTo: parcelId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch update multiple parcels
  /// TODO: Handle large batch operations (Firestore has limits)
  Future<void> batchUpdateParcels(List<Parcel> parcels) async {
    try {
      final batch = _firestore.batch();
      for (final parcel in parcels) {
        batch.set(_firestore.collection('parcels').doc(parcel.parcelId),
            parcel.toFirestore());
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== SEARCH & FILTER OPERATIONS ====================

  /// Search parcels by tracking number or recipient name
  /// TODO: Implement full-text search for better UX
  Future<List<Parcel>> searchParcels(String query) async {
    try {
      // Search by tracking number
      final trackingSnapshot = await _firestore
          .collection('parcels')
          .where('trackingNumber', isGreaterThanOrEqualTo: query)
          .where('trackingNumber', isLessThan: query + 'z')
          .get();

      // Search by recipient name
      final nameSnapshot = await _firestore
          .collection('parcels')
          .where('recipientName', isGreaterThanOrEqualTo: query)
          .where('recipientName', isLessThan: query + 'z')
          .get();

      final combined = [...trackingSnapshot.docs, ...nameSnapshot.docs];
      final uniqueDocs = <String, QueryDocumentSnapshot>{};

      for (final doc in combined) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map((doc) => Parcel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
