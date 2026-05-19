import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class DetectIngredientsFromImage {
  // Pre-defined set of known food/ingredient labels to filter out non-food noise
  static const Set<String> _foodLabels = {
    'food', 'vegetable', 'fruit', 'meat', 'chicken', 'beef', 'fish', 'egg',
    'tomato', 'potato', 'onion', 'garlic', 'carrot', 'apple', 'banana', 'orange',
    'cheese', 'bread', 'pasta', 'rice', 'milk', 'pepper', 'salt', 'sugar',
    'butter', 'oil', 'lemon', 'lime', 'strawberry', 'blueberry', 'broccoli',
    'spinach', 'lettuce', 'cucumber', 'mushroom', 'corn', 'beans', 'pork',
    'shrimp', 'salmon', 'avocado', 'ginger', 'honey', 'flour', 'yogurt',
  };

  Future<List<String>> call(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    
    try {
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
      
      final Set<String> detectedIngredients = {};
      
      for (ImageLabel label in labels) {
        final text = label.label.toLowerCase();
        
        // Very basic filtering: keep it if it's in our known list and has >60% confidence
        if (label.confidence > 0.6) {
          if (_foodLabels.contains(text)) {
             detectedIngredients.add(text);
          } else {
             // Let's also check if any word matches
             for (final word in text.split(' ')) {
                if (_foodLabels.contains(word)) {
                   detectedIngredients.add(word);
                }
             }
          }
        }
      }
      
      imageLabeler.close();
      return detectedIngredients.toList();
    } catch (e) {
      imageLabeler.close();
      throw Exception('Failed to detect ingredients: $e');
    }
  }
}
