import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OverdueChargesPage extends StatefulWidget {
  const OverdueChargesPage({Key? key}) : super(key: key);

  @override
  State<OverdueChargesPage> createState() => _OverdueChargesPageState();
}

class _OverdueChargesPageState extends State<OverdueChargesPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  /// Calculates only the overdue portion of the charge based on your rules.
  double _calculateOverdueCharge(String type, Timestamp? arrivalDate) {
    if (arrivalDate == null) {
      return 0.0;
    }

    final daysUncollected =
        DateTime.now().difference(arrivalDate.toDate()).inDays;
    final parcelType = type.toLowerCase();
    double overdueCharge = 0.0;

    final nonParcelTypes = ['letter', 'card', 'document', 'book'];

    if (nonParcelTypes.contains(parcelType)) {
      // Overdue after 2 weeks (14 days)
      if (daysUncollected > 14) {
        overdueCharge = 0.5 + (daysUncollected - 14) * 0.50;
      } else if(daysUncollected > 0 && daysUncollected <= 14 && daysUncollected == 0) {
        overdueCharge = 0.5;
      }
    } else {
      // Assumes 'Parcel', overdue after 3 days
      if (daysUncollected > 14) {
        // Penalty at day 14 is RM 2.00, then add daily charge
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
        title: const Text('Overdue Charges'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: currentUser == null
          ? const Center(child: Text('You must be logged in to see charges.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError ||
                    !userSnapshot.hasData ||
                    !userSnapshot.data!.exists) {
                  return const Center(
                      child: Text('Could not find user data.'));
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final studentId = userData['studentId'] as String?;

                if (studentId == null) {
                  return const Center(child: Text('User has no Student ID.'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parcels')
                      .where('studentId', isEqualTo: studentId)
                      .where('status', isEqualTo: 'Pending Pickup')
                      .snapshots(),
                  builder: (context, parcelSnapshot) {
                    if (parcelSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (parcelSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${parcelSnapshot.error}'));
                    }
                    if (!parcelSnapshot.hasData ||
                        parcelSnapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final allParcels = parcelSnapshot.data!.docs;
                    final overdueParcels = allParcels.where((doc) {
                      final parcel = doc.data() as Map<String, dynamic>;
                      final parcelType = parcel['type'] as String? ?? 'Parcel';
                      final arrivalDate = parcel['arrivalDate'] as Timestamp?;
                      return _calculateOverdueCharge(parcelType, arrivalDate) >
                          0;
                    }).toList();

                    if (overdueParcels.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      itemCount: overdueParcels.length,
                      itemBuilder: (context, index) {
                        final parcelDoc = overdueParcels[index];
                        final parcel =
                            parcelDoc.data() as Map<String, dynamic>;

                        final trackingNumber =
                            parcel['trackingNumber'] as String? ?? 'N/A';
                        final parcelType =
                            parcel['type'] as String? ?? 'Parcel';
                        final arrivalDate =
                            parcel['arrivalDate'] as Timestamp?;

                        final daysUncollected = arrivalDate != null
                            ? DateTime.now()
                                .difference(arrivalDate.toDate())
                                .inDays
                            : 0;

                        final charge =
                            _calculateOverdueCharge(parcelType, arrivalDate);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.warning_amber_rounded),
                            ),
                            title: Text(
                              'Tracking: $trackingNumber',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Overdue by $daysUncollected days\nType: $parcelType',
                            ),
                            trailing: Text(
                              'RM ${charge.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('You have no overdue parcels.',
              style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}