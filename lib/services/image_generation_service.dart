import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageGenerationException implements Exception {
  final String message;
  ImageGenerationException(this.message);

  @override
  String toString() => message;
}

class ImageGenerationService {
  Future<Uint8List> generateImage({
    required String prompt,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw ImageGenerationException(
        'No API key configured. Please add your OpenAI API key in Settings.',
      );
    }

    final fullPrompt =
        'A surreal, dreamlike artistic visualization of: $prompt. '
        'Style: ethereal, soft lighting, fantasy art, mysterious atmosphere';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': fullPrompt,
          'n': 1,
          'size': '1024x1024',
          'response_format': 'b64_json',
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ??
            'HTTP ${response.statusCode}';
        throw ImageGenerationException('API error: $errorMessage');
      }

      final json = jsonDecode(response.body);
      final data = json['data'] as List;
      if (data.isEmpty) {
        throw ImageGenerationException('No image returned from API');
      }

      final b64Json = data[0]['b64_json'] as String;
      return base64Decode(b64Json);
    } on ImageGenerationException {
      rethrow;
    } catch (e) {
      throw ImageGenerationException('Failed to generate image: $e');
    }
  }
}
