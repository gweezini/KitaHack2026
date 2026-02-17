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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PreAlertPage()),
                      );
                    },
                    icon: const Icon(Icons.notification_add, size: 18),
                    label: const Text('Expecting a parcel? Pre-alert us!'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange),
                    ),
                  ),
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

                          return ListView.builder(
                            itemCount: parcels.length,
                            itemBuilder: (context, index) {
                              final parcelDoc = parcels[index];
                              final parcel =
                                  parcelDoc.data() as Map<String, dynamic>;
                              final trackingNumber =
                                  parcel['trackingNumber'] as String? ?? 'N/A';
                              final arrivalDate =
                                  parcel['arrivalDate'] as Timestamp?;
                              final type =
                                  parcel['type'] as String? ?? 'Parcel';

                              if (_searchQuery.isNotEmpty &&
                                  !trackingNumber.contains(_searchQuery)) {
                                return const SizedBox.shrink();
                              }

                              String arrivalDateFormatted = 'Unknown';
                              if (arrivalDate != null) {
                                arrivalDateFormatted =
                                    DateFormat('d MMM yyyy, h:mm a')
                                        .format(arrivalDate.toDate());
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(Icons.local_shipping,
                                        color: Colors.blue),
                                  ),
                                  title: Text(trackingNumber),
                                  subtitle: Text(
                                      'Arrived: $arrivalDateFormatted\nType: $type'),
                                  trailing: const Icon(Icons.qr_code_scanner),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VerifyParcelPage(
                                          parcelId: parcelDoc.id,
                                          trackingNumber: trackingNumber,
                                          arrivalDate: arrivalDate,
                                          type: type,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
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
          const SnackBar(
              content: Text('This parcel is no longer available.')),
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