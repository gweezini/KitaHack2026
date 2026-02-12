/// Model for OCR (Optical Character Recognition) Results
/// Stores the extracted text data from parcel images via Google ML Kit
class OCRResult {
  final String trackingNumber;
  final String recipientName;
  final double confidence; // 0.0 to 1.0, confidence level of OCR extraction
  final String rawText; // Full text extracted from image
  final List<ExtractedField> extractedFields; // Individual extracted fields with confidence scores

  OCRResult({
    required this.trackingNumber,
    required this.recipientName,
    required this.confidence,
    required this.rawText,
    required this.extractedFields,
  });
}

/// Represents a single extracted field with its confidence score
class ExtractedField {
  final String fieldName; // e.g., 'tracking_number', 'recipient_name', 'sender_name'
  final String value;
  final double confidence; // 0.0 to 1.0

  ExtractedField({
    required this.fieldName,
    required this.value,
    required this.confidence,
  });
}
