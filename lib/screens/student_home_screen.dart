/// Home Screen for Student
/// Displays parcels for the logged-in student

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parcel_model.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import 'admin_scanner_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String studentId;

  const StudentHomeScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  late Future<List<Parcel>> _parcelsFuture;

  @override
  void initState() {
    super.initState();
    _parcelsFuture = _firestoreService.getParcelsByStudentId(widget.studentId);
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
    }
  }

  /// Handle parcel claim action
  void _handleClaimParcel(Parcel parcel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('TODO: Implement claim for ${parcel.parcelId}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parcels'),
        elevation: 2,
        actions: [
          // Admin scanner button (for testing)
          IconButton(
            icon: const Icon(Icons.camera),
            tooltip: 'Admin Scanner',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminScannerScreen(
                    adminId: widget.studentId,
                  ),
                ),
              );
            },
          ),
          // Menu
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile coming soon')),
                );
              } else if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Parcel>>(
        future: _parcelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _parcelsFuture =
                            _firestoreService.getParcelsByStudentId(widget.studentId);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final parcels = snapshot.data ?? [];

          if (parcels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No parcels yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parcels.length,
            itemBuilder: (context, index) {
              final parcel = parcels[index];
              return _buildParcelCard(context, parcel);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Track parcel feature coming soon')),
          );
        },
        child: const Icon(Icons.search),
        tooltip: 'Track New Parcel',
      ),
    );
  }

  /// Build parcel card widget
  Widget _buildParcelCard(BuildContext context, Parcel parcel) {
    final statusColor = _getStatusColor(parcel.status);
    final statusIcon = _getStatusIcon(parcel.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracking: ${parcel.trackingNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${parcel.senderInfo ?? "Unknown sender"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        parcel.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Received',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(parcel.dateReceived),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (parcel.estimatedDeliveryDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Est. Deadline',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(parcel.estimatedDeliveryDate!),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),

            // Late charge info if applicable
            if (parcel.lateClaimCharge != null && parcel.lateClaimCharge! > 0)
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Late claim charge: \$${parcel.lateClaimCharge!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Action buttons
            if (parcel.status == 'arrived')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleClaimParcel(parcel),
                  child: const Text('Claim Parcel'),
                ),
              )
            else if (parcel.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to parcel detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('TODO: View details for ${parcel.parcelId}')),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'claimed':
        return Colors.green;
      case 'arrived':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'delayed':
        return Colors.red;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon based on status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'claimed':
        return Icons.check_circle;
      case 'arrived':
        return Icons.home;
      case 'pending':
        return Icons.schedule;
      case 'delayed':
        return Icons.priority_high;
      case 'lost':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
