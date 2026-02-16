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

      final trackingPriorityRegex = RegExp(r'^(SPX|JNT|LEX|NJV|DHL|PL|ER|SHP|NVMY)[A-Z0-9]{5,25}$|^(MY|TH)[A-Z0-9]{10,25}$');
      final trackingNumericRegex = RegExp(r'^\d{12,15}$');
      final trackingGenericRegex = RegExp(r'^(?=.*[A-Z])[A-Z0-9]{10,20}$');
      
      final phoneRegex = RegExp(r'(?:60|0)1[0-9*]{8,10}');

      final nameBlacklist = [
        'ORDER', 'DETAILS', 'DETAIL', 'PENGIRIM', 'PENERIMA', 'ADDRESS', 
        'POSTCODE', 'TEL', 'PARCEL', 'WEIGHT', 'COD', 'MYR', 'RM', 
        'SHOPEE', 'LAZADA', 'EXPRESS', 'LOGISTICS', 'SENDER', 'RECIPIENT',
        'DATE', 'ID', 'SHIP', 'BY', 'STANDARD', 'DELIVERY', 'SELF', 'COLLECTION'
      ];

      final lines = extracted.split('\n');
      for (var line in lines) {
        String cleanLine = line.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
        
        final phoneLine = line
            .toUpperCase()
            .replaceAll('O', '0')
            .replaceAll(RegExp(r'[^0-9*]'), '');

        final phoneMatch = phoneRegex.firstMatch(phoneLine);
        
        if (phoneMatch != null) {
           String rawPhone = phoneMatch.group(0)!;
           bestPhoneCandidate = _normalizePhone(rawPhone);
        }

        if (trackingPriorityRegex.hasMatch(cleanLine)) {
            bestTrackingCandidate = cleanLine;
        } else if (trackingNumericRegex.hasMatch(cleanLine) && bestTrackingCandidate == null) {
            bestTrackingCandidate = cleanLine;
        } else if (trackingGenericRegex.hasMatch(cleanLine) && bestTrackingCandidate == null) {
              // avoid common non-tracking lines
              if (!line.toUpperCase().contains('ORDER') && !line.toUpperCase().contains('ID')) {
                bestTrackingCandidate = cleanLine;
              }
        }

        String potentialName = _normalizeNameForSearch(line);
        if (potentialName.startsWith('NAME')) potentialName = potentialName.substring(4).trim();
        if (potentialName.startsWith('PENERIMA')) potentialName = potentialName.substring(8).trim();
        if (potentialName.startsWith('RECIPIENT')) potentialName = potentialName.substring(9).trim();
        
        bool isBlacklisted = false;
        for (var weirdWord in nameBlacklist) {
          if (potentialName.contains(weirdWord)) { 
            isBlacklisted = true;
            break;
          }
        }

        if (phoneMatch == null && 
            !trackingGenericRegex.hasMatch(cleanLine) && 
            !isBlacklisted &&
            potentialName.split(' ').length >= 2 && 
            potentialName.length > 3) {
             potentialNames.add(potentialName);
        }
      }

      setState(() {
        if (bestTrackingCandidate != null) _trackingController.text = bestTrackingCandidate!;
        if (bestPhoneCandidate != null) _phoneController.text = bestPhoneCandidate!;
      });

      if (bestPhoneCandidate != null) {
        await _handlePhoneLookup(bestPhoneCandidate!);
      } else if (potentialNames.isNotEmpty) {
        await _handleNameLookup(potentialNames);
      } else {
        _showSnackBar('No phone or name detected. Manual Entry.');
      }

    } catch (e) {
      _showSnackBar('OCR Error: $e');
    }
  }

  Future<void> _handleNameLookup(List<String> candidates) async {
    _showSnackBar('Trying to match names...');
    
    int checks = 0;
    for (String name in candidates) {
      if (checks > 4) break; 
      
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('searchName', isEqualTo: name)
            .get();

        if (snapshot.docs.isNotEmpty) {
           final userData = snapshot.docs.first.data();
           _fillUserData(userData);
           _showSnackBar('Matched Name: $name');
           return; 
        }
      } catch (e) {
        print('Name lookup error: $e');
      }
      checks++;
    }
    
    _showSnackBar('No matching names found. Manual Entry.');
  }

  Future<void> _handlePhoneLookup(String rawPhone) async {
    final String phone = _normalizePhone(rawPhone); // normalize first (handles 60)
    final bool isMasked = phone.contains('*');

    if (!isMasked) {
      await _lookupByExactPhone(phone);
    } else {
      // Automatic prefix extraction (dynamic length)
      // Matches leading digits until it hits a non-digit (like *)
      final prefixMatch = RegExp(r'^\d+').firstMatch(phone);
      final prefix = prefixMatch?.group(0) ?? '';
      
      // Extract last 3-4 digits ONLY if they are actual digits at the end
      final suffixMatch = RegExp(r'(\d{3,4})$').firstMatch(phone);
      final suffix = suffixMatch?.group(1) ?? '';

      if (prefix.length >= 3 && suffix.isNotEmpty) {
        await _lookupByPartialPhone(prefix, suffix);
      } else {
        _showSnackBar('Masked phone not enough digits to match.');
      }
    }
  }

  Future<void> _lookupByExactPhone(String phone) async {
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
        } else {
           _showSelectionDialog(matches);
        }
      } else {
        _showSnackBar('Phone found, but no user registered.');
      }
    } catch (e) {
      print('Exact lookup error: $e');
    }
  }

  Future<void> _lookupByPartialPhone(String prefix, String suffix) async {
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
      } else if (matches.length > 1) {
        // === LEVEL 3: Multiple Matches ===
        _showSelectionDialog(matches);
      } else {
         _showSnackBar('No matching users found. Please enter manually.');
      }

    } catch (e) {
      print('Partial lookup error: $e');
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
        _nameController.text.isEmpty) {
      _showSnackBar('Tracking, phone number and name are required!');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('parcels').add({
        'trackingNumber': _trackingController.text.trim(),
        'studentName': _nameController.text.trim(),
        'studentId': _idController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'type': _parcelType,
        'status': 'Pending Pickup',
        'arrivalDate': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Parcel Registered Successfully!');
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
              value: _parcelType,
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
