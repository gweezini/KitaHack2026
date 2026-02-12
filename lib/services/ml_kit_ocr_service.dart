/// Google ML Kit Text Recognition Service
/// Handles OCR (Optical Character Recognition) from camera images to extract
/// tracking numbers and recipient names from parcels

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ocr_result_model.dart';

class MLKitOCRService {
  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }

  /// Pick image from camera and process OCR
  /// TODO: Add image quality validation and compression
  Future<OCRResult?> captureAndRecognizeFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress for faster processing
      );

      if (pickedFile == null) return null;

      return recognizeTextFromFile(File(pickedFile.path));
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from gallery and process OCR
  Future<OCRResult?> pickAndRecognizeFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return recognizeTextFromFile(File(pickedFile.path));
    } catch (e) {
      rethrow;
    }
  }

  /// Recognize text from file path
  /// TODO: 
  /// - Implement image preprocessing (brightness, contrast adjustment)
  /// - Add OCR result validation
  /// - Cache results for identical images
  Future<OCRResult?> recognizeTextFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return null;
      }

      // Extract tracking number and recipient name from recognized text
      final result = _parseOCRText(recognizedText.text);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Parse OCR text to extract tracking number and recipient name
  /// TODO: 
  /// - Improve extraction logic with regex patterns specific to courier services
  /// - Add ML-based field extraction instead of keyword matching
  /// - Handle multiple language support (if needed)
  OCRResult _parseOCRText(String rawText) {
    final lines = rawText.split('\n');
    String trackingNumber = '';
    String recipientName = '';
    List<ExtractedField> extractedFields = [];

    // TODO: Customize these patterns based on your parcel format
    // Example pattern for tracking number (alphanumeric, 8-15 chars)
    final trackingPattern = RegExp(r'[A-Z0-9]{8,15}');

    for (final line in lines) {
      final trimmed = line.trim();

      // Try to extract tracking number
      if (trackingPattern.hasMatch(trimmed) && trackingNumber.isEmpty) {
        final match = trackingPattern.firstMatch(trimmed);
        if (match != null) {
          trackingNumber = match.group(0) ?? '';
          extractedFields.add(ExtractedField(
            fieldName: 'tracking_number',
            value: trackingNumber,
            confidence: 0.85, // TODO: Use ML confidence scores
          ));
        }
      }

      // Try to extract recipient name (capitalized words)
      if (recipientName.isEmpty && _isLikelyName(trimmed)) {
        recipientName = trimmed;
        extractedFields.add(ExtractedField(
          fieldName: 'recipient_name',
          value: recipientName,
          confidence: 0.75,
        ));
      }
    }

    // Calculate overall confidence
    final overallConfidence = extractedFields.isNotEmpty
        ? extractedFields.map((f) => f.confidence).reduce((a, b) => a + b) /
            extractedFields.length
        : 0.0;

    return OCRResult(
      trackingNumber: trackingNumber,
      recipientName: recipientName,
      confidence: overallConfidence,
      rawText: rawText,
      extractedFields: extractedFields,
    );
  }

  /// Check if text is likely a name (heuristic)
  /// TODO: Improve with actual NLP or ML-based name detection
  bool _isLikelyName(String text) {
    if (text.length < 2 || text.length > 100) return false;

    // Should contain at least one capital letter
    if (!text.contains(RegExp(r'[A-Z]'))) return false;

    // Should not be all uppercase (tracking numbers)
    if (text == text.toUpperCase()) return false;

    // Should not contain special characters except space and hyphen
    if (text.contains(RegExp(r'[^a-zA-Z\s\-]'))) return false;

    return true;
  }

  /// Get overall confidence of extraction
  /// TODO: Implement confidence threshold for auto-acceptance
  bool isConfidenceAcceptable(OCRResult result, {double threshold = 0.7}) {
    return result.confidence >= threshold &&
        result.trackingNumber.isNotEmpty &&
        result.recipientName.isNotEmpty;
  }

  /// Validate extracted data
  /// TODO: Cross-reference with database or courier APIs
  Future<bool> validateExtraction(OCRResult result) async {
    // Basic validation
    if (result.trackingNumber.isEmpty || result.recipientName.isEmpty) {
      return false;
    }

    // TODO: Implement database validation
    // - Check if tracking number exists in system
    // - Verify recipient name matches in database
    // - Query courier API for real-time validation

    return true;
  }
}
