import 'package:equatable/equatable.dart';

class MealEntity extends Equatable {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? instructions;
  final String? thumbnailUrl;
  final String? youtubeUrl;
  final String? tags;
  final List<String> ingredients;
  final List<String> measurements;

  const MealEntity({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    this.thumbnailUrl,
    this.youtubeUrl,
    this.tags,
    this.ingredients = const [],
    this.measurements = const [],
  });

  List<MapEntry<String, String>> get ingredientMeasurements {
    final result = <MapEntry<String, String>>[];
    for (int i = 0; i < ingredients.length; i++) {
      if (ingredients[i].trim().isNotEmpty) {
        result.add(MapEntry(
          ingredients[i].trim(),
          i < measurements.length ? measurements[i].trim() : '',
        ));
      }
    }
    return result;
  }

  String? get youtubeVideoId {
    if (youtubeUrl == null) return null;
    final uri = Uri.tryParse(youtubeUrl!);
    return uri?.queryParameters['v'];
  }

  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  @override
  List<Object?> get props => [id, name, category, area];

  MealEntity copyWith({
    String? id,
    String? name,
    String? category,
    String? area,
    String? instructions,
    String? thumbnailUrl,
    String? youtubeUrl,
    String? tags,
    List<String>? ingredients,
    List<String>? measurements,
  }) {
    return MealEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      area: area ?? this.area,
      instructions: instructions ?? this.instructions,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      tags: tags ?? this.tags,
      ingredients: ingredients ?? this.ingredients,
      measurements: measurements ?? this.measurements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'area': area,
      'instructions': instructions,
      'thumbnailUrl': thumbnailUrl,
      'youtubeUrl': youtubeUrl,
      'tags': tags,
      'ingredients': ingredients,
      'measurements': measurements,
    };
  }

  factory MealEntity.fromMap(Map<String, dynamic> map) {
    return MealEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      area: map['area'] as String?,
      instructions: map['instructions'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      youtubeUrl: map['youtubeUrl'] as String?,
      tags: map['tags'] as String?,
      ingredients: List<String>.from(map['ingredients'] ?? []),
      measurements: List<String>.from(map['measurements'] ?? []),
    );
  }
}
