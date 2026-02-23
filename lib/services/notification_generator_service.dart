import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NotificationGeneratorService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<String> generatePersonalizedMessage({
    required String studentName,
    required String parcelType,
    required String trackingNumber,
    required String storageLocation,
  }) async {
    // Default message in case of any error or if API key is missing
    String defaultMessage =
        'hi';

    if (_apiKey == null || _apiKey!.isEmpty) {
      print('GEMINI_API_KEY not found in .env file. Using default notification.');
      return defaultMessage;
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!);
      final prompt =
          'Generate a warm, friendly, and humourous (max 30 words) notification for a student named $studentName with $parcelType with $trackingNumber with storage location: $storageLocation';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return defaultMessage;
      }
    } catch (e) {
      print("Gemini generation error: $e");
      return defaultMessage;
    }
  }
}