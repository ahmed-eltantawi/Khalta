import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/services/gemini_service.dart';

class DetectIngredientsFromImage {
  final GeminiService _geminiService;

  DetectIngredientsFromImage(this._geminiService);

  Future<List<String>> call(String imagePath, {Function(int)? onRetry}) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();


      final prompt = TextPart(
          'Identify the raw food ingredients in this image. '
          'Return ONLY specific ingredient names in singular form (e.g., "tomato", "onion", "banana", "chicken"). '
          'Do NOT return broad categories. "fruit", "vegetable", "food", or "ingredient" are INCORRECT. '
          'The output should be clean and ingredient-focused only. '
          'Return up to 3 ingredients separated by commas. If no food is detected, return an empty string.');
      final ext = imagePath.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final imagePart = DataPart(mime, bytes);

      final text = await _geminiService.generateContentWithRetry(
        promptParts: [prompt, imagePart],
        onRetry: onRetry,
      );

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
