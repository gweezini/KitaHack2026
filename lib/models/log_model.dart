/// Model for Activity Logs
/// Tracks all actions performed on parcels and users for audit purposes
class ActivityLog {
  final String logId;
  final String userId;
  final String? parcelId; // Null if log is not related to a specific parcel
  final String action; // 'scanned', 'claimed', 'verified', 'charged', 'notification_sent', etc.
  final String details; // Additional information about the action
  final DateTime timestamp;
  final String? ipAddress; // For security audit
  final String? deviceInfo; // Device information for audit

  ActivityLog({
    required this.logId,
    required this.userId,
    this.parcelId,
    required this.action,
    required this.details,
    required this.timestamp,
    this.ipAddress,
    this.deviceInfo,
  });

  /// Convert Firestore document to ActivityLog object
  /// TODO: Implement fromFirestore with proper timestamp handling
  factory ActivityLog.fromFirestore(Map<String, dynamic> data, String logId) {
    return ActivityLog(
      logId: logId,
      userId: data['userId'] ?? '',
      parcelId: data['parcelId'],
      action: data['action'] ?? '',
      details: data['details'] ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'],
      deviceInfo: data['deviceInfo'],
    );
  }

  /// Convert ActivityLog to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'parcelId': parcelId,
      'action': action,
      'details': details,
      'timestamp': timestamp,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
    };
  }
}
