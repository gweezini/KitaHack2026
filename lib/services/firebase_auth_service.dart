/// Firebase Authentication Service
/// Handles user authentication, registration, and account management
/// Integrates with Firebase Auth to verify student ID/email credentials

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user stream
  /// TODO: Implement stream management and proper error handling
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current authenticated user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Sign up with email and password
  /// TODO: 
  /// - Validate student ID format
  /// - Implement email verification (e.g., university domain check)
  /// - Add captcha for spam prevention
  /// - Store additional user metadata in Firestore
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String studentId,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      // Validate email domain (e.g., must be university email)
      // TODO: Implement domain validation logic
      if (!_isValidUniversityEmail(email)) {
        throw Exception('Please use your university email address');
      }

      // Create Firebase Auth user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Failed to create user account');

      // Create User document in Firestore
      final user = User(
        uid: uid,
        email: email,
        studentId: studentId,
        name: name,
        phoneNumber: phoneNumber,
        role: 'student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: false,
      );

      await _firestore.collection('users').doc(uid).set(user.toFirestore());

      // Send email verification
      await credential.user?.sendEmailVerification();

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Login with email and password
  /// TODO: Implement login attempt tracking for security
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Login failed');

      // Fetch user data from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return User.fromFirestore(userDoc.data() ?? {}, uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Verify user email
  /// TODO: Implement verification tracking and resend limits
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  /// TODO: Implement profile update validation
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateProfile(displayName: displayName, photoURL: photoUrl);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Change password
  /// TODO: Implement password strength validation
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Handle Firebase Auth exceptions
  /// TODO: Add localization for error messages
  void _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        throw Exception('The password provided is too weak.');
      case 'email-already-in-use':
        throw Exception('The account already exists for that email.');
      case 'invalid-email':
        throw Exception('The email address is not valid.');
      case 'user-disabled':
        throw Exception('This user account has been disabled.');
      case 'user-not-found':
        throw Exception('No user found for that email.');
      case 'wrong-password':
        throw Exception('Wrong password provided for that user.');
      default:
        throw Exception('Authentication error: ${e.message}');
    }
  }

  /// Validate university email domain
  /// TODO: Add your institution's email domains
  bool _isValidUniversityEmail(String email) {
    // Example: Allow emails ending with @university.edu
    final validDomains = ['@university.edu', '@student.university.edu'];
    return validDomains.any((domain) => email.endsWith(domain));
  }
}
