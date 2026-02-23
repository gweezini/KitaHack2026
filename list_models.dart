import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('No .env file found');
    return;
  }
  
  final lines = envFile.readAsLinesSync();
  String apiKey = '';
  for (var line in lines) {
    if (line.trim().startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey.isEmpty) {
    print('No API key found in .env');
    return;
  }

  print('Using API Key: ' + apiKey);
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  
  final responseBody = await response.transform(utf8.decoder).join();
  final data = jsonDecode(responseBody);
  
  if (data['models'] != null) {
    for (var model in data['models']) {
      print(model['name'].toString() + ' - ' + model['displayName'].toString() + ' - ' + model['supportedGenerationMethods'].toString());
    }
  } else {
    print(responseBody);
  }
}
