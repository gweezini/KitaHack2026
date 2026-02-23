import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'pre_alert_page.dart';
import 'dart:async';

class TrackParcelPage extends StatefulWidget {
  const TrackParcelPage({Key? key}) : super(key: key);

  @override
  State<TrackParcelPage> createState() => _TrackParcelPageState();
}

class _TrackParcelPageState extends State<TrackParcelPage> {
  String? _studentId;
  bool _isLoadingId = true;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _studentId = doc.data()?['studentId'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching student ID: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingId = false;
        });
      }
    }
  }

  double _calculateOverdueCharge(String type, Timestamp? arrivalDate) {
    if (arrivalDate == null) return 0.0;

    final daysUncollected =
        DateTime.now().difference(arrivalDate.toDate()).inDays;
    final parcelType = type.toLowerCase();
    double overdueCharge = 0.0;

    final nonParcelTypes = ['letter', 'document'];

    if (nonParcelTypes.contains(parcelType)) {
      if (daysUncollected > 14) {
        overdueCharge = 0.5 + (daysUncollected - 14) * 0.50;
      } else if (daysUncollected >= 0 && daysUncollected <= 14) {
        overdueCharge = 0.5;
      }
    } else {
      if (daysUncollected > 14) {
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
        title: const Text('My Parcels'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Pre-Alert Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Tracking Number...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toUpperCase();
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoadingId
                ? const Center(child: CircularProgressIndicator())
                : _studentId == null
                    ? const Center(child: Text('Student ID not found.'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('parcels')
                            .where('studentId', isEqualTo: _studentId)
                            .where('status', isEqualTo: 'Pending Pickup')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 80, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No pending parcels.',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            );
                          }

                          final parcels = snapshot.data!.docs;

                          // Calculate Total Count and Total Charges
                          int totalParcels = 0;
                          double totalCharges = 0.0;
                          final List<QueryDocumentSnapshot> filteredParcels =
                              [];

                          for (var doc in parcels) {
                            final parcel = doc.data() as Map<String, dynamic>;
                            final trackingNumber =
                                parcel['trackingNumber'] as String? ?? '';

                            if (_searchQuery.isNotEmpty &&
                                !trackingNumber.contains(_searchQuery)) {
                              continue;
                            }

                            filteredParcels.add(doc);
                            totalParcels++;
                            totalCharges += _calculateOverdueCharge(
                                parcel['type'] as String? ?? 'Parcel',
                                parcel['arrivalDate'] as Timestamp?);
                          }

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                // === SUMMARY CARD ===
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                        color: Colors.blue.shade100, width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text('Pending Parcels',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$totalParcels',
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          height: 40,
                                          width: 1,
                                          color: Colors.grey.shade300),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text('Total Amount Due',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13)),
                                            const SizedBox(height: 4),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'RM ${totalCharges.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: totalCharges > 0
                                                        ? Colors.red.shade700
                                                        : Colors.green),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // === PARCEL LIST ===
                                filteredParcels.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(32.0),
                                        child: Center(
                                            child: Text(
                                                'No parcels match your search.')),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: filteredParcels.length,
                                        itemBuilder: (context, index) {
                                          final parcelDoc =
                                              filteredParcels[index];
                                          final parcel = parcelDoc.data()
                                              as Map<String, dynamic>;
                                          final trackingNumber =
                                              parcel['trackingNumber']
                                                      as String? ??
                                                  'N/A';
                                          final arrivalDate =
                                              parcel['arrivalDate']
                                                  as Timestamp?;
                                          final type =
                                              parcel['type'] as String? ??
                                                  'Parcel';

                                          if (_searchQuery.isNotEmpty &&
                                              !trackingNumber
                                                  .contains(_searchQuery)) {
                                            return const SizedBox.shrink();
                                          }

                                          String arrivalDateFormatted =
                                              'Unknown';
                                          if (arrivalDate != null) {
                                            arrivalDateFormatted = DateFormat(
                                                    'd MMM yyyy, h:mm a')
                                                .format(arrivalDate.toDate());
                                          }

                                          final charge =
                                              _calculateOverdueCharge(
                                                  type, arrivalDate);

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                child: const Icon(
                                                    Icons.local_shipping,
                                                    color: Colors.blue),
                                              ),
                                              title: Text(trackingNumber),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Type: $type'),
                                                  Text(
                                                      'Arrived: $arrivalDateFormatted'),
                                                  if (charge > 0)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4.0),
                                                      child: Text(
                                                        'Fee: RM ${charge.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              trailing: const Icon(
                                                  Icons.qr_code_scanner),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        VerifyParcelPage(
                                                      parcelId: parcelDoc.id,
                                                      trackingNumber:
                                                          trackingNumber,
                                                      arrivalDate: arrivalDate,
                                                      type: type,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class VerifyParcelPage extends StatefulWidget {
  final String parcelId;
  final String trackingNumber;
  final Timestamp? arrivalDate;
  final String type;

  const VerifyParcelPage({
    Key? key,
    required this.parcelId,
    required this.trackingNumber,
    required this.arrivalDate,
    required this.type,
  }) : super(key: key);

  @override
  State<VerifyParcelPage> createState() => _VerifyParcelPageState();
}

class _VerifyParcelPageState extends State<VerifyParcelPage> {
  StreamSubscription<DocumentSnapshot>? _parcelSubscription;

  @override
  void initState() {
    super.initState();
    _listenForCollection();
  }

  void _listenForCollection() {
    _parcelSubscription = FirebaseFirestore.instance
        .collection('parcels')
        .doc(widget.parcelId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      if (!snapshot.exists) {
        // Document was deleted while listening.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This parcel is no longer available.')),
        );
        Navigator.of(context).pop();
        return;
      }

      // The cast is safe because we checked for existence.
      final data = snapshot.data() as Map<String, dynamic>;

      if (data['status'] == 'Collected') {
        // Stop listening to avoid multiple dialogs
        await _parcelSubscription?.cancel();
        _parcelSubscription = null;

        if (mounted) {
          _showCollectionSuccessDialog(
              (data['overdueCharge'] as num?)?.toDouble() ?? 0.0);
        }
      }
    }, onError: (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error listening to parcel status: $error')),
        );
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _showCollectionSuccessDialog(double charge) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Collection Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your parcel has been marked as collected.'),
            const SizedBox(height: 16),
            Text(
              'Overdue Charge: RM ${charge.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: charge > 0 ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pop dialog and then pop the verify page
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _parcelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Collection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Parcel: ${widget.trackingNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Present this QR code to the admin to collect your parcel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.parcelId,
                  version: QrVersions.auto,
                  size: 250.0,
                  gapless: false,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Waiting for admin to scan...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
