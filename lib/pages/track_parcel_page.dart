import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TrackParcelPage extends StatefulWidget {
  const TrackParcelPage({Key? key}) : super(key: key);

  @override
  State<TrackParcelPage> createState() => _TrackParcelPageState();
}

class _TrackParcelPageState extends State<TrackParcelPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String? _studentId;
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  Future<void> _fetchStudentId() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
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
      body: _isLoadingId
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                        final parcel = parcelDoc.data() as Map<String, dynamic>;
                        final trackingNumber =
                            parcel['trackingNumber'] as String? ?? 'N/A';
                        final arrivalDate = parcel['arrivalDate'] as Timestamp?;
                        final type = parcel['type'] as String? ?? 'Parcel';

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
  bool _isProcessing = false;
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> _scanAndVerify() async {
    setState(() => _isProcessing = true);
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final inputImage = InputImage.fromFile(File(pickedFile.path));
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Check if tracking number exists in scanned text
      // We remove spaces to make matching robust
      final scannedText =
          recognizedText.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      final targetTracking =
          widget.trackingNumber.replaceAll(RegExp(r'\s+'), '').toUpperCase();

      if (scannedText.contains(targetTracking)) {
        await _completeCollection();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Tracking number not found in scan. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  double _calculateOverdueCharge(String type, Timestamp? arrivalDate) {
    if (arrivalDate == null) return 0.0;

    final daysUncollected =
        DateTime.now().difference(arrivalDate.toDate()).inDays;
    final parcelType = type.toLowerCase();
    double overdueCharge = 0.0;

    final nonParcelTypes = ['letter', 'card', 'document', 'book'];

    if (nonParcelTypes.contains(parcelType)) {
      if (daysUncollected > 14) {
        overdueCharge = (daysUncollected - 14) * 0.50;
      }
    } else {
      if (daysUncollected > 14) {
        overdueCharge = 2.00 + (daysUncollected - 14) * 0.50;
      } else if (daysUncollected > 7) {
        overdueCharge = 2.00;
      } else if (daysUncollected > 3) {
        overdueCharge = 1.00;
      }
    }
    return overdueCharge;
  }

  Future<void> _completeCollection() async {
    final charge = _calculateOverdueCharge(widget.type, widget.arrivalDate);

    await FirebaseFirestore.instance
        .collection('parcels')
        .doc(widget.parcelId)
        .update({
      'status': 'Collected',
      'collectedAt': FieldValue.serverTimestamp(),
      'overdueCharge': charge,
    });

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
            const Text('Parcel has been marked as collected.'),
            const SizedBox(height: 16),
            Text(
              'Overdue Charge: RM ${charge.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Collection')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
            const SizedBox(height: 32),
            Text(
              'Verify Parcel: ${widget.trackingNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please scan the parcel label to verify collection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _scanAndVerify,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Label'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}