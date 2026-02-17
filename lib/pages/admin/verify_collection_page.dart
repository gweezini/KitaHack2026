import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyCollectionPage extends StatefulWidget {
  const VerifyCollectionPage({super.key});

  @override
  State<VerifyCollectionPage> createState() => _VerifyCollectionPageState();
}

class _VerifyCollectionPageState extends State<VerifyCollectionPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? parcelId = barcodes.first.rawValue;
      if (parcelId != null && parcelId.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });
        _scannerController.stop();
        _handleParcelId(parcelId);
      }
    }
  }

  Future<void> _handleParcelId(String parcelId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('parcels').doc(parcelId).get();

      if (!mounted) return;

      if (!doc.exists || doc.data() == null) {
        _showErrorAndRestart('Parcel not found.');
        return;
      }

      final data = doc.data()!;
      if (data['status'] != 'Pending Pickup') {
        _showErrorAndRestart('Parcel is not pending pickup.');
        return;
      }

      final charge = _calculateOverdueCharge(data['type'], data['arrivalDate']);

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tracking: ${data['trackingNumber'] ?? 'N/A'}'),
              Text('Name: ${data['studentName'] ?? 'N/A'}'),
              Text('Student ID: ${data['studentId'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              Text(
                'Overdue Charge: RM ${charge.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: charge > 0 ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await doc.reference.update({
          'status': 'Collected',
          'collectedAt': FieldValue.serverTimestamp(),
          'overdueCharge': charge,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parcel marked as collected!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } else {
        _restartScanning();
      }
    } catch (e) {
      _showErrorAndRestart('An error occurred: $e');
    }
  }

  void _showErrorAndRestart(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    _restartScanning();
  }

  void _restartScanning() {
    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  double _calculateOverdueCharge(String? type, Timestamp? arrivalDate) {
    if (arrivalDate == null) return 0.0;

    final daysUncollected = DateTime.now().difference(arrivalDate.toDate()).inDays;
    final parcelType = (type ?? 'parcel').toLowerCase();
    double overdueCharge = 0.0;

    final nonParcelTypes = ['letter', 'card', 'document', 'book'];

    if (nonParcelTypes.contains(parcelType)) {
      if (daysUncollected > 14) {
        overdueCharge = (daysUncollected - 14) * 0.50;
      }
    } else { // It's a parcel
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to Verify Collection')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}