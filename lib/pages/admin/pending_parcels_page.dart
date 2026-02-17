import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class PendingParcelsPage extends StatelessWidget {
  const PendingParcelsPage({Key? key}) : super(key: key);

  // Function to mark a parcel as collected
  Future<void> _markAsCollected(BuildContext context, String parcelId) async {
    try {
      await FirebaseFirestore.instance
          .collection('parcels')
          .doc(parcelId)
          .update({
        'status': 'Collected',
        'collectedAt': FieldValue.serverTimestamp(),
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

              String arrivalDateFormatted = 'Unknown time';
              if (arrivalDate != null) {
                arrivalDateFormatted =
                    DateFormat('d MMM yyyy, h:mm a').format(arrivalDate.toDate());
              }

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
                  subtitle: Text(
                    'ID: $studentId\nPhone: $phoneNumber\nTracking: $trackingNumber\nArrived: $arrivalDateFormatted',
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => _markAsCollected(context, parcelDoc.id),
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