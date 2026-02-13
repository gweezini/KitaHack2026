import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;

  Future<void> login(String email, String password, {bool isAdmin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password are required';
      }

      if (!email.contains('@')) {
        throw 'Please enter a valid email address';
      }

      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      // Admin login validation
      if (isAdmin && !email.endsWith('@university.admin')) {
        throw 'Admin email must end with @university.admin';
      }

      // Simulate successful login
      // In a real app, you would make an API call here
      _isAuthenticated = true;
      _isAdmin = isAdmin;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    _isAdmin = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
