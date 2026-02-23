import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:kita_hack_2026/services/notification_generator_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Use gemini-2.5-flash model to extract information from the image (more accurate)
//The model will return a valid JSON object with the following fields:
//If there is problem such as no wifi connection or model is not available or free API limit reached, use the ML KIT+Regex to extract information from the image
class OCRScanPage extends StatefulWidget {
  const OCRScanPage({super.key});

  @override
  State<OCRScanPage> createState() => _OCRScanPageState();
}

class _OCRScanPageState extends State<OCRScanPage> {
  XFile? _image;
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
  bool _isSearching = false;

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
          _image = pickedFile;
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





  Future<void> _processImage(XFile image) async {
    if (kIsWeb) {
      _showSnackBar('OCR is not supported on Web. Please enter details manually.');
      return;
    }
    
    _showSnackBar('Analyzing image with AI...');
    
    // 1. Try Gemini Vision API First
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        final model = ai.GenerativeModel(
          model: 'gemini-2.5-flash',//use gemini
          apiKey: apiKey,
        );

        final imageBytes = await image.readAsBytes();
        final prompt = ai.TextPart('''
          You are an expert logistics data extractor. Analyze this shipping label image.
          Extract the following information and return ONLY a valid JSON object. Do not wrap in markdown tags or add any conversation text.
          If a field cannot be found, return null for that field.

          {
            "recipient_name": "Full name of the receiver",
            "phone_number": "Phone number (remove all dashes, spaces, and country codes like +60, starting with 0)",
            "tracking_number": "The main alphanumeric tracking number or AWB",
            "courier_company": "e.g., Shopee Express, J&T, PosLaju, NinjaVan"
          }
        ''');
        
        final imagePart = ai.DataPart('image/jpeg', imageBytes);
        final response = await model.generateContent([
          ai.Content.multi([prompt, imagePart])
        ]);

        final responseText = response.text;
        if (responseText != null && responseText.isNotEmpty) {
            final String cleanJsonString = responseText
              .replaceAll(RegExp(r'```json\n?'), '')
              .replaceAll(RegExp(r'```'), '')
              .trim();
              
            final Map<String, dynamic> data = jsonDecode(cleanJsonString);

            final tracking = data['tracking_number'] as String?;
            final phone = data['phone_number'] as String?;
            final name = data['recipient_name'] as String?;
            final courier = data['courier_company'] as String?;
            
            setState(() {
              if (tracking != null) _trackingController.text = tracking;
              if (phone != null) _phoneController.text = _normalizePhone(phone);
            });

            // Check pre-alert
            if (tracking != null) {
               bool preAlertFound = await _checkPreAlert(tracking);
               if (preAlertFound) return;
            }

            bool foundUser = false;
            if (phone != null && phone.isNotEmpty) {
              _showSnackBar('Searching by phone (Gemini)...');
              foundUser = await _handlePhoneLookup(_normalizePhone(phone));
            } 
            
            if (!foundUser && name != null && name.isNotEmpty) {
              _showSnackBar('No phone? Trying to match name (Gemini)...');
              final cleanName = _normalizeNameForSearch(name);
              await _handleNameLookup([cleanName]);
            } else if (!foundUser) {
              _showSnackBar('Gemini could not find a registered user. Please enter manually.');
            }
            
            return; // Success, exit function
        }
      }
    } catch (e) {
      print('Gemini API Error: $e');
      _showGeminiErrorDialog(e.toString());
      _showSnackBar('Gemini AI failed, falling back to basic OCR...');
    }

    // 2. Fallback to ML Kit Text Recognition if Gemini fails or no API key
    final inputImage = InputImage.fromFile(File(image.path));
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String extracted = recognizedText.text;
      String? bestTrackingCandidate;
      String? bestPhoneCandidate;
      List<String> potentialNames = [];

      // Regex for Tracking Number
      final trackingPriorityRegex = RegExp(r'\b(SPX|JNT|LEX|NJV|DHL|PL|ER|SHP|NVMY)[A-Z0-9]{5,25}\b|\b(MY|TH)[A-Z0-9]{10,25}\b');
      final trackingNumericRegex = RegExp(r'\b\d{12,15}\b');
      final trackingGenericRegex = RegExp(r'(?<![A-Z0-9])[A-Z0-9]{10,20}(?![A-Z0-9])');
      
      final phoneRegex = RegExp(r'(?:60|0)1[0-9*]{8,10}');

      final lines = extracted.split('\n');
      for (var line in lines) {
        String upperLine = line.toUpperCase().trim();
        String cleanLine = upperLine.replaceAll(RegExp(r'[\s-]'), '');

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
              if (!upperLine.contains('ORDER') && !upperLine.contains('ID')) {
                bestTrackingCandidate = genericMatch.group(0);
              }
        }

        String nameOnly = upperLine;
        int addressIndex = upperLine.indexOf(RegExp(r'JALAN|LORONG|TAMAN|BUKIT|KG|LOT|NO\.|BLOCK|BLOK|KAMPUNG|BATU|LEVEL|FLOOR|UNIT'));
        if (addressIndex != -1) {
          nameOnly = upperLine.substring(0, addressIndex).trim();
        }

        String finalPotentialName = _normalizeNameForSearch(nameOnly)
            .replaceFirst(RegExp(r'^(NAME|RECIPIENT|PENERIMA|TO|SHIP TO|BUYER|JAME|TECIPIENT|ENDER)\s+'), '')
            .trim();

        if (finalPotentialName.length > 3 && finalPotentialName.split(' ').length >= 2) {
           if (!finalPotentialName.contains('SHOPEE') && !finalPotentialName.contains('LAZADA')) {
              potentialNames.add(finalPotentialName);
           }
        }
      }

      setState(() {
        if (bestTrackingCandidate != null) _trackingController.text = bestTrackingCandidate;
        if (bestPhoneCandidate != null) _phoneController.text = bestPhoneCandidate;
      });

      if (bestTrackingCandidate != null) {
         bool preAlertFound = await _checkPreAlert(bestTrackingCandidate);
         if (preAlertFound) return; 
      }

      bool foundUser = false;

      if (bestPhoneCandidate != null) {
        _showSnackBar('Searching by phone (Fallback)...');
        foundUser = await _handlePhoneLookup(bestPhoneCandidate);
      } 
      
      if (!foundUser && potentialNames.isNotEmpty) {
        _showSnackBar('Trying to match names (Fallback)...');
        await _handleNameLookup(potentialNames);
      } else if (!foundUser) {
        _showSnackBar('No phone or name detected. Please enter manually.');
      }
    } catch (e) {
      _showSnackBar('Fallback OCR Error: $e');
    }
  }

  // === Pre-Alert Logic ===
  Future<bool> _checkPreAlert(String trackingNumber) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pre_alerts')
          .doc(trackingNumber)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (data['status'] == 'pending') {
          setState(() {
            _nameController.text = data['userName'] ?? '';
            _phoneController.text = data['userPhone'] ?? '';
            _idController.text = data['studentId'] ?? '';
            
            // Mark as Pre-Alert Match visually or toast
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Matched via PRE-ALERT!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          });
          return true;
        }
      }
    } catch (e) {
      print('Pre-alert check error: $e');
    }
    return false;
  }
  // =======================

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

  void _showGeminiErrorDialog(String errorLine) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gemini API Error'),
          content: SingleChildScrollView(
            child: Text(errorLine),
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
        if (_isSearching) {
          _showSnackBar('No user found with this phone number.');
        } else {
          _showSnackBar('Phone found, but no user registered. Trying Name...');
        }
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
        // Generate a personalized notification message using our new service
        final notificationService = NotificationGeneratorService();
        final String notificationMessage = await notificationService.generatePersonalizedMessage(
          studentName: _nameController.text.trim(),
          parcelType: _parcelType,
          trackingNumber: _trackingController.text.trim(),
          storageLocation: _storageLocationController.text.trim(),
        );

         try {
           await FirebaseFirestore.instance.collection('notifications').add({
             'studentId': _idController.text.trim(),
             'title': 'Parcel Arrived',
             'message': notificationMessage,
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
                      child: kIsWeb
                          ? Image.network(_image!.path, fit: BoxFit.cover)
                          : Image.file(File(_image!.path), fit: BoxFit.cover),
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
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _isSearching
                    ? Transform.scale(
                        scale: 0.5,
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          if (_phoneController.text.isNotEmpty) {
                            setState(() => _isSearching = true);
                            await _handlePhoneLookup(_phoneController.text);
                            setState(() => _isSearching = false);
                          } else {
                            _showSnackBar('Enter a phone number first');
                          }
                        },
                      ),
              ),
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
