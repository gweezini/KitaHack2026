/// Model for Parcel tracking
/// Stores parcel information including tracking details and status
class Parcel {
  final String parcelId;
  final String trackingNumber;
  final String recipientName;
  final String recipientStudentId;
  final String status; // 'arrived', 'claimed', 'pending', 'delayed', 'lost'
  final DateTime dateReceived;
  final DateTime? dateClaimedBy;
  final double? lateClaimCharge; // In currency units
  final String? senderInfo; // Extracted from OCR
  final String? parcelDescription;
  final bool requiresSignature;
  final String? scannedByAdminId; // Admin who scanned the parcel
  final DateTime? estimatedDeliveryDate;
  final String? currentLocation; // For tracking purposes
  final bool notificationSent; // Track if notification was sent

  Parcel({
    required this.parcelId,
    required this.trackingNumber,
    required this.recipientName,
    required this.recipientStudentId,
    required this.status,
    required this.dateReceived,
    this.dateClaimedBy,
    this.lateClaimCharge,
    this.senderInfo,
    this.parcelDescription,
    required this.requiresSignature,
    this.scannedByAdminId,
    this.estimatedDeliveryDate,
    this.currentLocation,
    required this.notificationSent,
  });

  /// Convert Firestore document to Parcel object
  /// TODO: Implement fromFirestore with proper timestamp handling
  factory Parcel.fromFirestore(Map<String, dynamic> data, String parcelId) {
    return Parcel(
      parcelId: parcelId,
      trackingNumber: data['trackingNumber'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientStudentId: data['recipientStudentId'] ?? '',
      status: data['status'] ?? 'pending',
      dateReceived: (data['dateReceived'] as dynamic)?.toDate() ?? DateTime.now(),
      dateClaimedBy: (data['dateClaimedBy'] as dynamic)?.toDate(),
      lateClaimCharge: (data['lateClaimCharge'] ?? 0).toDouble(),
      senderInfo: data['senderInfo'],
      parcelDescription: data['parcelDescription'],
      requiresSignature: data['requiresSignature'] ?? false,
      scannedByAdminId: data['scannedByAdminId'],
      estimatedDeliveryDate: (data['estimatedDeliveryDate'] as dynamic)?.toDate(),
      currentLocation: data['currentLocation'],
      notificationSent: data['notificationSent'] ?? false,
    );
  }

  /// Convert Parcel object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'trackingNumber': trackingNumber,
      'recipientName': recipientName,
      'recipientStudentId': recipientStudentId,
      'status': status,
      'dateReceived': dateReceived,
      'dateClaimedBy': dateClaimedBy,
      'lateClaimCharge': lateClaimCharge,
      'senderInfo': senderInfo,
      'parcelDescription': parcelDescription,
      'requiresSignature': requiresSignature,
      'scannedByAdminId': scannedByAdminId,
      'estimatedDeliveryDate': estimatedDeliveryDate,
      'currentLocation': currentLocation,
      'notificationSent': notificationSent,
    };
  }

  /// Check if parcel claim is late (depends on your business logic - e.g., 7 days)
  /// TODO: Define the grace period for claiming parcels in your app
  bool isClaimLate() {
    final gracePeriodDays = 7; // Customize this value
    final deadline = dateReceived.add(Duration(days: gracePeriodDays));
    return DateTime.now().isAfter(deadline) && status != 'claimed';
  }

  /// Calculate late claim charge based on days delayed
  /// TODO: Implement your charge calculation logic
  double calculateLateCharge() {
    if (status == 'claimed') return 0;
    final chargePerDay = 5.0; // Customize charge per day
    final daysLate = DateTime.now().difference(dateReceived).inDays - 7;
    return daysLate > 0 ? daysLate * chargePerDay : 0;
  }

  /// Create a copy with modified fields
  Parcel copyWith({
    String? parcelId,
    String? trackingNumber,
    String? recipientName,
    String? recipientStudentId,
    String? status,
    DateTime? dateReceived,
    DateTime? dateClaimedBy,
    double? lateClaimCharge,
    String? senderInfo,
    String? parcelDescription,
    bool? requiresSignature,
    String? scannedByAdminId,
    DateTime? estimatedDeliveryDate,
    String? currentLocation,
    bool? notificationSent,
  }) {
    return Parcel(
      parcelId: parcelId ?? this.parcelId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      recipientName: recipientName ?? this.recipientName,
      recipientStudentId: recipientStudentId ?? this.recipientStudentId,
      status: status ?? this.status,
      dateReceived: dateReceived ?? this.dateReceived,
      dateClaimedBy: dateClaimedBy ?? this.dateClaimedBy,
      lateClaimCharge: lateClaimCharge ?? this.lateClaimCharge,
      senderInfo: senderInfo ?? this.senderInfo,
      parcelDescription: parcelDescription ?? this.parcelDescription,
      requiresSignature: requiresSignature ?? this.requiresSignature,
      scannedByAdminId: scannedByAdminId ?? this.scannedByAdminId,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      currentLocation: currentLocation ?? this.currentLocation,
      notificationSent: notificationSent ?? this.notificationSent,
    );
  }
}
