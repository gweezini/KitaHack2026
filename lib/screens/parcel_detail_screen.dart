/// Parcel Detail Screen
/// Displays comprehensive information about a specific parcel
/// including tracking status, ETA, late charges, and action buttons

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parcel_model.dart';
import '../services/firestore_service.dart';
import '../services/eta_service.dart';

class ParcelDetailScreen extends StatefulWidget {
  final String parcelId;

  const ParcelDetailScreen({
    super.key,
    required this.parcelId,
  });

  @override
  State<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends State<ParcelDetailScreen> {
  final _firestoreService = FirestoreService();
  final _etaService = ETAService();

  late Future<Parcel?> _parcelFuture;

  @override
  void initState() {
    super.initState();
    _parcelFuture = _firestoreService.getParcelById(widget.parcelId);
  }

  /// Handle claim parcel action
  /// TODO: Implement payment collection if late charges apply
  Future<void> _handleClaimParcel(Parcel parcel) async {
    // TODO: Implement claim logic with:
    // - Payment processing if late charges exist
    // - Receipt generation
    // - Firestore update to mark as claimed
    // - Activity log entry
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Process parcel claim')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcel Details'),
        elevation: 2,
      ),
      body: FutureBuilder<Parcel?>(
        future: _parcelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Parcel not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final parcel = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(parcel),
                const SizedBox(height: 24),

                // Basic information
                _buildSection(
                  title: 'Parcel Information',
                  children: [
                    _buildInfoRow('Tracking Number', parcel.trackingNumber),
                    _buildInfoRow('Recipient Name', parcel.recipientName),
                    _buildInfoRow('From', parcel.senderInfo ?? 'Unknown'),
                    if (parcel.parcelDescription != null)
                      _buildInfoRow('Description', parcel.parcelDescription!),
                  ],
                ),
                const SizedBox(height: 20),

                // Dates
                _buildSection(
                  title: 'Timeline',
                  children: [
                    _buildInfoRow(
                      'Date Received',
                      DateFormat('MMM dd, yyyy hh:mm a').format(parcel.dateReceived),
                    ),
                    if (parcel.estimatedDeliveryDate != null)
                      _buildInfoRow(
                        'Est. Claim Deadline',
                        DateFormat('MMM dd, yyyy')
                            .format(parcel.estimatedDeliveryDate!),
                      ),
                    if (parcel.dateClaimedBy != null)
                      _buildInfoRow(
                        'Claimed On',
                        DateFormat('MMM dd, yyyy hh:mm a')
                            .format(parcel.dateClaimedBy!),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Late charges if applicable
                if (parcel.lateClaimCharge != null && parcel.lateClaimCharge! > 0)
                  Column(
                    children: [
                      _buildSection(
                        title: 'Late Claim Charge',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Amount Due:'),
                                    Text(
                                      '\$${parcel.lateClaimCharge!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'A late claim charge has been applied due to delayed pickup.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Action buttons
                if (parcel.status == 'arrived')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleClaimParcel(parcel),
                      child: const Text('Claim Parcel'),
                    ),
                  ),

                const SizedBox(height: 24),

                // TODO: Add activity log / tracking history
                // TODO: Add QR code for proof of identity
                // TODO: Add parcel image gallery
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build status card
  Widget _buildStatusCard(Parcel parcel) {
    final statusColor = _getStatusColor(parcel.status);
    final statusIcon = _getStatusIcon(parcel.status);
    final statusText = _getStatusText(parcel.status);

    return Card(
      color: statusColor.withOpacity(0.1),
      border: Border.all(color: statusColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section with title and content
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
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

  /// Get status text
  String _getStatusText(String status) {
    switch (status) {
      case 'claimed':
        return 'Claimed';
      case 'arrived':
        return 'Arrived & Waiting';
      case 'pending':
        return 'In Transit';
      case 'delayed':
        return 'Delayed';
      case 'lost':
        return 'Lost';
      default:
        return 'Unknown';
    }
  }
}
