import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreAlertPage extends StatefulWidget {
  const PreAlertPage({super.key});

  @override
  State<PreAlertPage> createState() => _PreAlertPageState();
}

class _PreAlertPageState extends State<PreAlertPage> {
  final _trackingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _submitPreAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user details for redundant storage (faster read)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final String trackingNumber = _trackingController.text.trim().toUpperCase();

      // Check if already exists
      final existing = await FirebaseFirestore.instance
          .collection('pre_alerts')
          .doc(trackingNumber)
          .get();

      if (existing.exists) {
        throw Exception('This tracking number is already pre-alerted.');
      }

      await FirebaseFirestore.instance
          .collection('pre_alerts')
          .doc(trackingNumber) // Use tracking number as ID for easy lookup
          .set({
        'trackingNumber': trackingNumber,
        'userId': user.uid,
        'userName': userData['fullName'] ?? 'Unknown',
        'userPhone': userData['phoneNumber'] ?? '',
        'studentId': userData['studentId'] ?? '',
        'status': 'pending', // pending, arrived
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fast Track Claim setup successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Track Claim Setup'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Expecting a parcel with a different name?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the tracking number here so we can match it to you automatically when it arrives.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _trackingController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                  hintText: 'e.g. SPX123456789',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a tracking number';
                  }
                  if (value.trim().length < 5) {
                    return 'Tracking number too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPreAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SET UP FAST TRACK CLAIM',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
