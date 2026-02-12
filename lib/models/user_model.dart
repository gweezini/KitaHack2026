/// Model for User (Student/Admin)
/// Stores user information synchronized with Firebase Authentication and Firestore
class User {
  final String uid;
  final String email;
  final String studentId;
  final String name;
  final String phoneNumber;
  final String role; // 'student' or 'admin'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Email verified status

  User({
    required this.uid,
    required this.email,
    required this.studentId,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isVerified,
  });

  /// Convert Firestore document to User object
  /// TODO: Implement fromFirestore method that parses Firestore document data
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    return User(
      uid: uid,
      email: data['email'] ?? '',
      studentId: data['studentId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? 'student',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Convert User object to Firestore document
  /// TODO: Ensure all fields are properly serialized for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'studentId': studentId,
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isVerified': isVerified,
    };
  }

  /// Create a copy of User with modified fields
  User copyWith({
    String? uid,
    String? email,
    String? studentId,
    String? name,
    String? phoneNumber,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
