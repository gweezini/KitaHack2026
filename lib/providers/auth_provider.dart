import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

  String? _studentId;

// Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  String? get studentId => _studentId;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _isAuthenticated = true;
        _isAdmin = user.email?.toLowerCase().contains('admin') ?? false;
        
        // Fetch studentId from Firestore
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            _studentId = doc.data()?['studentId'];
          }
        } catch (e) {
          print("Error fetching user data in AuthProvider: $e");
        }
      } else {
        _isAuthenticated = false;
        _isAdmin = false;
        _studentId = null;
      }
      notifyListeners();
    });
  }

// Login Function
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Login failed.';
    } catch (e) {
      _errorMessage = 'Connection failed.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Register Function (Added this to fix your error)
  Future<void> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // After successful registration, save user details to Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'uid': userCredential.user!.uid,
          'createdAt': Timestamp.now(),
          'isAdmin':
              userCredential.user!.email?.toLowerCase().contains('admin') ??
                  false,
        });
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Registration failed.';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Logout Function
  Future<void> logout() async {
    await _auth.signOut();
    _isAuthenticated = false;
    _isAdmin = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
