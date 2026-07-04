import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/services/gemini_service.dart';
import '../entities/receipt_ingredient.dart';

/// Extracts structured ingredient data from a receipt or ingredient list image
/// using Gemini vision API.
class ExtractIngredientsFromReceipt {
  final GeminiService _geminiService;

  ExtractIngredientsFromReceipt(this._geminiService);

  Future<List<ReceiptIngredient>> call(String imagePath, {Function(int)? onRetry}) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();


      final prompt = TextPart(
        '''You are analyzing an image of a supermarket receipt or a handwritten/printed ingredient list.

Your task: Extract ONLY food and cooking-related ingredients from the text in this image.

RULES:
1. Extract only food items, produce, meat, dairy, grains, spices, condiments, beverages, and cooking ingredients.
2. IGNORE all non-food items: cleaning products, toiletries, household items, pet supplies, etc.
3. IGNORE prices, discounts, taxes, subtotals, totals, store names, addresses, dates, loyalty info, payment details, receipt numbers, and barcodes.
4. Normalize each ingredient name to a clean, singular English name (e.g., "BNLS CHKN BRST" → "chicken breast", "GRN PEPPERS" → "green pepper", "TOMATOS" → "tomato").
5. Expand common grocery abbreviations (e.g., "org" → "organic", "whl" → "whole", "frz" → "frozen").
6. If the same ingredient appears multiple times, merge them by summing quantities.
7. For each ingredient, estimate a confidence score (0.0 to 1.0) based on how certain you are about the identification.
8. Extract quantities and units when visible (e.g., "2 kg chicken" → quantity: 2, unit: "kg").

Return a JSON array of objects with this structure:
[
  {
    "name": "ingredient name in singular lowercase English",
    "quantity": 1.0,
    "unit": "piece",
    "confidence": 0.95
  }
]

- "name" is required (string, lowercase, singular).
- "quantity" is optional (number, null if not visible).
- "unit" is optional (string like "piece", "kg", "g", "L", "ml", "cup", "tbsp", "tsp", or null if not visible).
- "confidence" is required (number between 0.0 and 1.0).

If no food items are found, return an empty array: []
Do NOT include any text outside the JSON array.''',
      );

      final ext = imagePath.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final imagePart = DataPart(mime, bytes);

      final text = await _geminiService.generateContentWithRetry(
        promptParts: [prompt, imagePart],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
        onRetry: onRetry,
      );

      if (text.isEmpty || text == '[]') return [];

      final List<dynamic> parsed = json.decode(text);

      final ingredients = <ReceiptIngredient>[];
      final seenNames = <String, int>{}; // name → index for dedup

      for (final item in parsed) {
        if (item is! Map<String, dynamic>) continue;
        final rawName = (item['name'] as String?)?.trim().toLowerCase() ?? '';
        if (rawName.isEmpty) continue;

        final quantity = _parseDouble(item['quantity']);
        final unit = item['unit'] as String?;
        final confidence = (_parseDouble(item['confidence']) ?? 0.9)
            .clamp(0.0, 1.0);

        // Merge duplicates by summing quantities
        if (seenNames.containsKey(rawName)) {
          final existingIdx = seenNames[rawName]!;
          final existing = ingredients[existingIdx];
          final mergedQty = (existing.quantity ?? 0) + (quantity ?? 0);
          ingredients[existingIdx] = existing.copyWith(
            quantity: mergedQty > 0 ? mergedQty : null,
            // Keep the higher confidence
            confidence: confidence > existing.confidence
                ? confidence
                : existing.confidence,
          );
        } else {
          seenNames[rawName] = ingredients.length;
          ingredients.add(ReceiptIngredient(
            name: rawName,
            quantity: quantity,
            unit: unit,
            confidence: confidence,
          ));
        }
      }

      return ingredients;
    } catch (e) {
      throw Exception('Failed to extract ingredients from receipt: $e');
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
