/// Admin Scanner Screen
/// Allows admin staff to scan parcels using camera and ML Kit OCR
/// Note: Camera/OCR features are limited on web platform

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/ml_kit_ocr_service.dart';
import '../services/firestore_service.dart';
import '../models/parcel_model.dart';
import '../models/ocr_result_model.dart';

class AdminScannerScreen extends StatefulWidget {
  final String adminId;

  const AdminScannerScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  final _ocrService = MLKitOCRService();
  final _firestoreService = FirestoreService();

  OCRResult? _lastScanResult;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// Handle camera capture and OCR processing
  /// TODO: 
  /// - Add image preprocessing
  /// - Implement confidence scoring
  /// - Add manual correction UI for low-confidence results
  /// - Implement batch scanning
  Future<void> _handleCameraCapture() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.captureAndRecognizeFromCamera();

      if (result != null && mounted) {
        setState(() {
          _lastScanResult = result;
          _isProcessing = false;
        });

        // Show confirmation dialog
        _showScanResultDialog(result);
      } else if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error scanning parcel: $e';
          _isProcessing = false;
        });
      }
    }
  }

  /// Show dialog for scan result confirmation
  /// TODO: 
  /// - Allow manual correction of OCR results
  /// - Add field-by-field confidence display
  /// - Implement rescan option
  void _showScanResultDialog(OCRResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Result'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overall Confidence:'),
                  Text(
                    '${(result.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: result.confidence > 0.8 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Extracted fields
              const Text(
                'Extracted Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Tracking number
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tracking Number:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    TextFormField(
                      initialValue: result.trackingNumber,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      // TODO: Allow editing
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Recipient name
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipient Name:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    TextFormField(
                      initialValue: result.recipientName,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      // TODO: Allow editing
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Raw text (debugging)
              if (false) // TODO: Add debug toggle
                ExpansionTile(
                  title: const Text('Raw Text (Debug)'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        result.rawText,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmScanAndSaveParcel(result);
            },
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }

  /// Confirm scan result and save parcel to database
  /// TODO: 
  /// - Verify recipient exists in database
  /// - Handle duplicate tracking numbers
  /// - Send notification to recipient
  /// - Create activity log entry
  Future<void> _confirmScanAndSaveParcel(OCRResult result) async {
    if (result.trackingNumber.isEmpty || result.recipientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      // TODO: Lookup recipient by name to get studentId
      final newParcel = Parcel(
        parcelId: '', // Will be generated by Firestore
        trackingNumber: result.trackingNumber,
        recipientName: result.recipientName,
        recipientStudentId: '', // TODO: Lookup from database
        status: 'arrived',
        dateReceived: DateTime.now(),
        requiresSignature: false,
        scannedByAdminId: widget.adminId,
        notificationSent: false,
      );

      final parcelId = await _firestoreService.addParcel(newParcel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parcel saved: $parcelId'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving parcel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Parcel'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info, size: 64, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              const Text(
                'Camera Scanner Not Available on Web',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This feature requires a mobile or desktop app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Parcel'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera icon section
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Capture parcel image',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scan button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleCameraCapture,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera),
                label: Text(_isProcessing ? 'Processing...' : 'Scan Parcel'),
              ),
            ),
            const SizedBox(height: 16),

            // Gallery button
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        // TODO: Implement gallery image picker
                        final result =
                            await _ocrService.pickAndRecognizeFromGallery();
                        if (result != null && mounted) {
                          setState(() => _lastScanResult = result);
                          _showScanResultDialog(result);
                        }
                      },
                icon: const Icon(Icons.image),
                label: const Text('Choose from Gallery'),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Last scan result
            if (_lastScanResult != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Last Scan Result:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tracking:'),
                              Text(
                                _lastScanResult!.trackingNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Recipient:'),
                              Text(
                                _lastScanResult!.recipientName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // TODO: Implement scanning history view
          ],
        ),
      ),
    );
  }
}
