import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as my_auth;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController(); // Student or Staff ID
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // New Phone Controller
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _phoneController.text.isEmpty || // Validate Phone
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final authProvider =
        Provider.of<my_auth.AuthProvider>(context, listen: false);

    try {
      // Create User in Firebase Auth
      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Check if registration was successful (no error message)
      if (authProvider.errorMessage == null) {
        final User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Normalize Name for Search
          String normalizeNameForSearch(String input) {
            return input
                .trim()
                .replaceAll(RegExp(r'[^A-Za-z ]'), '') // keep letters + space only
                .replaceAll(RegExp(r'\s+'), ' ')       // collapse multiple spaces
                .toUpperCase();
          }

          // Normalize Phone for Search
          String normalizePhone(String input) {
            // Keep digits only (Register MUST be a real number)
            String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');

            // Convert 60XXXXXXXXX -> 0XXXXXXXXX (e.g., 60123456789 -> 0123456789)
            if (cleaned.startsWith('60')) {
              cleaned = '0${cleaned.substring(2)}';
            }
            return cleaned;
          }

          final String displayName = _nameController.text.trim();
          final String searchName = normalizeNameForSearch(displayName);
          final String cleanPhone = normalizePhone(_phoneController.text.trim());

          //Save additional data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fullName': displayName,     // keep original for UI display
            'searchName': searchName,    // normalized name for exact matching
            'studentId': _idController.text.trim(),
            'phoneNumber': cleanPhone,   // Normalized Phone
            'email': _emailController.text.trim(),
            'role': _emailController.text.toLowerCase().contains('.admin')
                ? 'admin'
                : 'student', // Simple role adjustment
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')),
            );
            Navigator.pop(context); // Go back to Login Page
          }
        }
      } else {
        // Show Auth Error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<my_auth.AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Student / Staff ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g. 0123456789',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'REGISTER',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
