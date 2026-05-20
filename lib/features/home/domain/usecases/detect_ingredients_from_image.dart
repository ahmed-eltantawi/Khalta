import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_constants.dart';

class DetectIngredientsFromImage {
  Future<List<String>> call(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiConstants.geminiApiKey,
      );

      final prompt = TextPart(
        'Identify the raw food ingredients in this image. '
        'Return ONLY specific ingredient names in singular form (e.g., "tomato", "onion", "banana", "chicken"). '
        'Do NOT return broad categories. "fruit", "vegetable", "food", or "ingredient" are INCORRECT. '
        'The output should be clean and ingredient-focused only. '
        'Return up to 3 ingredients separated by commas. If no food is detected, return an empty string.'
      );
      final ext = imagePath.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final imagePart = DataPart(mime, bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return [];

      final ingredients = text
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      return ingredients;
    } catch (e) {
      throw Exception('Failed to detect ingredients via Gemini: $e');
    }
  }
}
