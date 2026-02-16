import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

// Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _isAuthenticated = true;
        _isAdmin = user.email?.toLowerCase().contains('admin') ?? false;
      } else {
        _isAuthenticated = false;
        _isAdmin = false;
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
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
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
