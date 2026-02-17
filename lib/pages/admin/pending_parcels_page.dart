import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class PendingParcelsPage extends StatelessWidget {
  const PendingParcelsPage({Key? key}) : super(key: key);

  // Function to mark a parcel as collected
  Future<void> _markAsCollected(BuildContext context, String parcelId,
      String parcelType, Timestamp? arrivalDate) async {
    try {
      // Calculate the charge at the moment of collection
      final charge = _calculateOverdueCharge(parcelType, arrivalDate);

      await FirebaseFirestore.instance
          .collection('parcels')
          .doc(parcelId)
          .update({
        'status': 'Collected',
        'collectedAt': FieldValue.serverTimestamp(),
        'overdueCharge': charge, // Save the calculated charge
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parcel marked as collected.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Calculates overdue charges based on parcel type and arrival date.
  double _calculateOverdueCharge(String type, Timestamp? arrivalDate) {
    if (arrivalDate == null) return 0.0;

    final daysUncollected =
        DateTime.now().difference(arrivalDate.toDate()).inDays;
    final parcelType = type.toLowerCase();
    double overdueCharge = 0.0;

    final nonParcelTypes = ['letter', 'card', 'document', 'book'];

    if (nonParcelTypes.contains(parcelType)) {
      // Overdue for non-parcels after 14 days
      if (daysUncollected > 14) {
        overdueCharge = 0.5 + (daysUncollected - 14) * 0.50;
      } else if (daysUncollected >= 0 && daysUncollected <= 14) {
        overdueCharge = 0.5;
      }
    } else {
      // Overdue for parcels after 3 days
      if (daysUncollected > 14) {
        // After 14 days, fee is RM 2.00 + RM 0.50/day
        overdueCharge = 3.00 + (daysUncollected - 14) * 0.50;
      } else if (daysUncollected > 7) {
        overdueCharge = 3.00;
      } else if (daysUncollected > 3) {
        overdueCharge = 2.00;
      } else {
        overdueCharge = 1.00;
      }
    }
    return overdueCharge;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Parcels'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parcels')
            .where('status', isEqualTo: 'Pending Pickup')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending parcels found.',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final parcels = snapshot.data!.docs;

          return ListView.builder(
            itemCount: parcels.length,
            itemBuilder: (context, index) {
              final parcelDoc = parcels[index];
              final parcel = parcelDoc.data() as Map<String, dynamic>;

              final recipientName = parcel['studentName'] as String? ?? 'N/A';
              final trackingNumber =
                  parcel['trackingNumber'] as String? ?? 'N/A';
              final studentId = parcel['studentId'] as String? ?? 'N/A';
              final phoneNumber = parcel['phoneNumber'] as String? ?? 'N/A';
              final arrivalDate = parcel['arrivalDate'] as Timestamp?;
              final parcelType = parcel['type'] as String? ?? 'Parcel';

              String arrivalDateFormatted = 'Unknown time';
              if (arrivalDate != null) {
                arrivalDateFormatted =
                    DateFormat('d MMM yyyy, h:mm a').format(arrivalDate.toDate());
              }

              // Calculate overdue charge
              final charge = _calculateOverdueCharge(parcelType, arrivalDate);

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade300,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.inventory),
                  ),
                  title: Text(
                    recipientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: $studentId'),
                      Text('Phone: $phoneNumber'),
                      Text('Tracking: $trackingNumber'),
                      Text('Arrived: $arrivalDateFormatted'),
                      if (charge > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Charge: RM ${charge.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _markAsCollected(
                        context, parcelDoc.id, parcelType, arrivalDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Collect'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}