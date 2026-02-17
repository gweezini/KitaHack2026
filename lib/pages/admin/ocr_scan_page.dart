import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OCRScanPage extends StatefulWidget {
  const OCRScanPage({super.key});

  @override
  State<OCRScanPage> createState() => _OCRScanPageState();
}

class _OCRScanPageState extends State<OCRScanPage> {
  File? _image;
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final _trackingController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // New Phone Controller
  final _idController = TextEditingController();
  final _storageLocationController = TextEditingController(); // Storage Location

  String _parcelType = 'Parcel';
  final List<String> _parcelTypes = ['Parcel', 'Letter', 'Document'];
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    _trackingController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _storageLocationController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isProcessing = true;
          _trackingController.clear();
          _nameController.clear();
          _phoneController.clear();
          _idController.clear();
        });
        await _processImage(_image!);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _normalizeNameForSearch(String input) {
    return input.trim().replaceAll(RegExp(r'[^A-Za-z ]'), '').replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }

  String _normalizePhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^0-9*]'), '');

    if (cleaned.startsWith('60')) {
      cleaned = '0${cleaned.substring(2)}';
    }
    return cleaned;
  }





  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String extracted = recognizedText.text;
      String? bestTrackingCandidate;
      String? bestPhoneCandidate;
      List<String> potentialNames = [];

      // Regex for Tracking Number
      // We look for patterns anywhere in the string, but STRICTLY matching the format
      final trackingPriorityRegex = RegExp(r'\b(SPX|JNT|LEX|NJV|DHL|PL|ER|SHP|NVMY)[A-Z0-9]{5,25}\b|\b(MY|TH)[A-Z0-9]{10,25}\b');
      final trackingNumericRegex = RegExp(r'\b\d{12,15}\b');
      final trackingGenericRegex = RegExp(r'(?<![A-Z0-9])[A-Z0-9]{10,20}(?![A-Z0-9])');
      
      final phoneRegex = RegExp(r'(?:60|0)1[0-9*]{8,10}');

      final nameBlacklist = [
        'ORDER', 'DETAILS', 'DETAIL', 'PENGIRIM', 'PENERIMA', 'ADDRESS', 
        'POSTCODE', 'TEL', 'PARCEL', 'WEIGHT', 'COD', 'MYR', 'RM', 
        'SHOPEE', 'LAZADA', 'EXPRESS', 'LOGISTICS', 'SENDER', 'RECIPIENT',
        'DATE', 'ID', 'SHIP', 'BY', 'STANDARD', 'DELIVERY', 'SELF', 'COLLECTION',
        'KG', 'G', 'LBS', 'PCS', 'CM', 'MM', 'NO', 'NUM', 'NUMBER', 'BILL', 'AWB',
        // Address Blacklist
        'JALAN', 'LORONG', 'BATU', 'TAMAN', 'BUKIT', 'KAMPUNG', 'KG', 
        'SIMPANG', 'PLOT', 'LOT', 'BLOCK', 'BLOK', 'LEVEL', 'FLOOR', 'UNIT',
        'PORT', 'DICKSON', 'NEGERI', 'SEMBILAN', 'MELAKA', 'JOHOR', 'PAHANG',
        'SELANGOR', 'KUALA', 'LUMPUR', 'PUTRAJAYA', 'PERAK', 'KEDAH', 'PERLIS',
        'KELANTAN', 'TERENGGANU', 'SABAH', 'SARAWAK', 'LABUAN', 'DISTRICT',
        'JAYA', 'UTAMA', 'BARU', 'LAMA', 'SEKSYEN', 'SEKOLAH', 'OFFICE', 'RUMAH'
      ];

      final lines = extracted.split('\n');
      for (var line in lines) {
        String upperLine = line.toUpperCase().trim();
        String cleanLine = upperLine.replaceAll(RegExp(r'[\s-]'), '');

        // 1. Identify Phone and Tracking (Keep existing logic)
        final phoneLine = upperLine.replaceAll('O', '0').replaceAll(RegExp(r'[^0-9*]'), '');
        final phoneMatch = phoneRegex.firstMatch(phoneLine);
        
        if (phoneMatch != null) {
           String rawPhone = phoneMatch.group(0)!;
           bestPhoneCandidate = _normalizePhone(rawPhone);
        }

        final priorityMatch = trackingPriorityRegex.firstMatch(cleanLine);
        final numericMatch = trackingNumericRegex.firstMatch(cleanLine);
        final genericMatch = trackingGenericRegex.firstMatch(cleanLine);

        if (priorityMatch != null) {
            bestTrackingCandidate = priorityMatch.group(0);
        } else if (numericMatch != null && bestTrackingCandidate == null) {
            bestTrackingCandidate = numericMatch.group(0);
        } else if (genericMatch != null && bestTrackingCandidate == null) {
              // avoid common non-tracking lines
              if (!upperLine.contains('ORDER') && !upperLine.contains('ID')) {
                bestTrackingCandidate = genericMatch.group(0);
              }
        }

        // Enhanced Name Extraction Logic for Shopee labels
        // Even if the line has numbers, try to extract name
        String nameOnly = upperLine;
        
        // Cut off address keywords
        int addressIndex = upperLine.indexOf(RegExp(r'JALAN|LORONG|TAMAN|BUKIT|KG|LOT|NO\.|BLOCK|BLOK|KAMPUNG|BATU|LEVEL|FLOOR|UNIT'));
        if (addressIndex != -1) {
          nameOnly = upperLine.substring(0, addressIndex).trim();
        }

        // Clean leading keywords (Handles common OCR typos like "JAME" for "NAME") because sometimes it cut as half
        String finalPotentialName = _normalizeNameForSearch(nameOnly)
            .replaceFirst(RegExp(r'^(NAME|RECIPIENT|PENERIMA|TO|SHIP TO|BUYER|JAME|TECIPIENT|ENDER)\s+'), '')
            .trim();

        // Core Change: Allow lines with numbers if they look like names
        // Do not exclude based on isTracking or digits presence
        if (finalPotentialName.length > 3 && finalPotentialName.split(' ').length >= 2) {
           // Exclude logistics company names
           if (!finalPotentialName.contains('SHOPEE') && !finalPotentialName.contains('LAZADA')) {
              potentialNames.add(finalPotentialName);
           }
        }
      }

      setState(() {
        if (bestTrackingCandidate != null) _trackingController.text = bestTrackingCandidate;
        if (bestPhoneCandidate != null) _phoneController.text = bestPhoneCandidate;
      });

      bool foundUser = false;

      if (bestPhoneCandidate != null) {
        _showSnackBar('Searching by phone...');
        foundUser = await _handlePhoneLookup(bestPhoneCandidate!);
      } 
      
      if (!foundUser && potentialNames.isNotEmpty) {
        _showSnackBar('No phone? Trying to match names...');
        await _handleNameLookup(potentialNames);
      } else if (!foundUser) {
        _showSnackBar('No phone or name detected. Please enter manually.');
      }
    } catch (e) {
      _showSnackBar('OCR Error: $e');
    }
  }

  Future<void> _handleNameLookup(List<String> candidates) async {
    _showSnackBar('Searching database for names...');
    List<String> logs = []; // Log for debugging
    logs.add("Candidates: ${candidates.join(', ')}");

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      logs.add("Total Users in DB: ${snapshot.docs.length}");
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Critical Fix: Fallback to fullName if searchName is missing
        String rawDbName = data['searchName'] ?? data['fullName'] ?? ""; 
        
        // Clean DB name: Remove spaces/symbols, Uppercase (e.g. "Gwee Zi Ni" -> "GWEEZINI")
        String dbNameClean = rawDbName.toString().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
        
        if (dbNameClean.isEmpty) continue;

        for (String scannedLine in candidates) {
          String scannedClean = scannedLine.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
          
          // Log only if it's somewhat similar to avoid spam, or just log first few
          if (scannedClean.isNotEmpty && dbNameClean.contains(scannedClean)) {
             logs.add("Partial Match: $scannedClean in $dbNameClean");
          }

          if (scannedClean.contains(dbNameClean) || dbNameClean.contains(scannedClean)) {
            _fillUserData(data);
            _showSnackBar('Success! Matched: ${data['fullName']}');
            return; 
          }
          
          if (scannedClean.length > 5 && dbNameClean.length > 5) {
             if (scannedClean.substring(0, scannedClean.length - 1) == dbNameClean ||
                 dbNameClean.substring(0, dbNameClean.length - 1) == scannedClean) {
                _fillUserData(data);
                _showSnackBar('Fuzzy Match Success!');
                return;
             }
          }
        }
      }
    } catch (e) {
      logs.add("Error: $e");
    }

    // If we reach here, no match was found. Show Debug Dialog.
    _showDebugDialog(logs);
  }

  void _showDebugDialog(List<String> logs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('OCR Debug Report'),
          content: SingleChildScrollView(
            child: Text(logs.join('\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _handlePhoneLookup(String rawPhone) async {
    final String phone = _normalizePhone(rawPhone); // normalize first (handles 60)
    final bool isMasked = phone.contains('*');

    if (!isMasked) {
      return await _lookupByExactPhone(phone);
    } else {
      // Automatic prefix extraction (dynamic length)
      // Matches leading digits until it hits a non-digit (like *)
      final prefixMatch = RegExp(r'^\d+').firstMatch(phone);
      final prefix = prefixMatch?.group(0) ?? '';
      
      // Extract last 3-4 digits ONLY if they are actual digits at the end
      final suffixMatch = RegExp(r'(\d{3,4})$').firstMatch(phone);
      final suffix = suffixMatch?.group(1) ?? '';

      if (prefix.length >= 3 && suffix.isNotEmpty) {
        return await _lookupByPartialPhone(prefix, suffix);
      } else {
        _showSnackBar('Masked phone not enough digits to match.');
        return false;
      }
    }
  }

  Future<bool> _lookupByExactPhone(String phone) async {
     try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> matches = snapshot.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        if (matches.length == 1) {
           final userData = matches.first;
           _fillUserData(userData);
           _showSnackBar('Exact Match Found!');
           return true;
        } else {
           _showSelectionDialog(matches);
           return true; // Consider selection dialog as "found"
        }
      } else {
        _showSnackBar('Phone found, but no user registered. Trying Name...');
        return false;
      }
    } catch (e) {
      print('Exact lookup error: $e');
      return false;
    }
  }

  Future<bool> _lookupByPartialPhone(String prefix, String suffix) async {
    try {
      final start = prefix;
      final end = '$prefix\uf8ff';

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isGreaterThanOrEqualTo: start)
          .where('phoneNumber', isLessThanOrEqualTo: end) 
          .get();

      // Filter in memory for suffix
      final List<Map<String, dynamic>> matches = [];
      for (var doc in snapshot.docs) {
        String dbPhone = doc.data()['phoneNumber'] ?? '';
        if (dbPhone.endsWith(suffix)) {
          final data = doc.data();
          data['id'] = doc.id; // Capture Doc ID
          matches.add(data);
        }
      }

      if (matches.length == 1) {
        // === LEVEL 2: Single Match ===
        _fillUserData(matches.first);
        _showSnackBar('Auto-matched masked phone!');
        return true;
      } else if (matches.length > 1) {
        // === LEVEL 3: Multiple Matches ===
        _showSelectionDialog(matches);
        return true;
      } else {
         return false; // Let it fallback to name
      }

    } catch (e) {
      print('Partial lookup error: $e');
      return false;
    }
  }





  // Helper to fill data
  void _fillUserData(Map<String, dynamic> data) {
    setState(() {
      _nameController.text = data['fullName'] ?? '';
      _idController.text = data['studentId'] ?? '';
      
      // Always show full phone from DB if available
      final dbPhone = (data['phoneNumber'] ?? '').toString();
      if (dbPhone.isNotEmpty) {
        _phoneController.text = dbPhone; 
      }
    });
  }

  void _showSelectionDialog(List<Map<String, dynamic>> matches) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Multiple Matches Found'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final user = matches[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user['fullName'] ?? 'Unknown'),
                  subtitle: Text(user['phoneNumber'] ?? ''),
                  onTap: () {
                    _fillUserData(user);
                    Navigator.pop(context); // Close dialog
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }




  // Save Parcel to Database
  Future<void> _saveParcel() async {
    if (_trackingController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _nameController.text.isEmpty ||
        _storageLocationController.text.isEmpty) { // Require Storage Location
      _showSnackBar('Tracking, phone, name and storage location are required!');
      return;
    }

    try {
      // 1. Save Parcel with 'Pending Pickup' status
      DocumentReference parcelRef = await FirebaseFirestore.instance.collection('parcels').add({
        'trackingNumber': _trackingController.text.trim(),
        'studentName': _nameController.text.trim(),
        'studentId': _idController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'storageLocation': _storageLocationController.text.trim(),
        'type': _parcelType,
        'status': 'Pending Pickup', // Updated Status
        'arrivalDate': FieldValue.serverTimestamp(),
      });

      // 2. Send Notification (if studentId exists)
      if (_idController.text.isNotEmpty) {
         try {
           await FirebaseFirestore.instance.collection('notifications').add({
             'studentId': _idController.text.trim(),
             'title': 'Parcel Arrived',
             'message': 'Your parcel (${_trackingController.text}) is ready for pickup at ${_storageLocationController.text.trim()}.',
             'parcelId': parcelRef.id,
             'isRead': false,
             'timestamp': FieldValue.serverTimestamp(),
           });
         } catch (e) {
           print("Notification Error: $e");
         }
      }

      _showSnackBar('Parcel Registered & User Notified!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Save Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Register Parcel'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Preview Area
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.5)),
              ),
              child: _image == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 60, color: Colors.deepOrange),
                        SizedBox(height: 10),
                        Text('Take a photo of the parcel label'),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),
            
            // Buttons Area
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.deepOrange),
                  ),
                ),
              ],
            ),
            
            if (_isProcessing) const LinearProgressIndicator(color: Colors.deepOrange),
            const Divider(height: 40),

            // Form Area
            TextField(
              controller: _trackingController,
              decoration: const InputDecoration(labelText: 'Tracking Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers)),
            ),
             const SizedBox(height: 15),
             // New Phone Field
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _parcelType,
              items: _parcelTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _parcelType = val!),
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _storageLocationController,
              decoration: const InputDecoration(labelText: 'Storage Location (Shelf)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shelves)),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _saveParcel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('CONFIRM & SAVE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
