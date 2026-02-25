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
        'Hi \$studentName! Your \$parcelType (Tracking: \$trackingNumber) has arrived! Please use your QR code in the app to claim it.';

    if (_apiKey == null || _apiKey!.isEmpty) {
      print('GEMINI_API_KEY not found in .env file. Using default notification.');
      return defaultMessage;
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey!);
      
      final prompt = '''
        You are an enthusiastic and friendly university parcel room assistant bot.
        A new \$parcelType has just arrived for a student named \$studentName. 
        The tracking number is \$trackingNumber.
        
        Write a very short, warm push notification (around 20-30 words) to tell them it's here.
        CRITICAL: You MUST remind them to "collect it within 3 days to avoid late charges."
        Remind them to use the QR code in the app to claim it.
        Keep it natural and energetic. Do NOT mention the storage location (\$storageLocation). 
        Do NOT use emojis.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        return defaultMessage;
      }
    } catch (e) {
      print("Gemini generation error: \$e");
      return defaultMessage;
    }
  }
}