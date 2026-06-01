import 'package:equatable/equatable.dart';

class HealthProfileEntity extends Equatable {
  final List<String> dietaryPreferences; // vegetarian, vegan, gluten-free, etc.
  final List<String> healthConditions; // diabetes, high-bp, weight-loss, etc.
  final int dailyCalorieTarget;

  static const List<String> availableDiets = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'Halal',
  ];

  static const List<String> availableConditions = [
    'Weight Loss',
    'High Protein',
    'Low Carb',
    'Low Sodium',
    'Diabetic-Friendly',
  ];

  // Ingredient exclusions per diet
  static const Map<String, List<String>> dietExclusions = {
    'Vegetarian': [
      'chicken',
      'beef',
      'pork',
      'lamb',
      'turkey',
      'bacon',
      'ham',
      'fish',
      'salmon',
      'tuna'
    ],
    'Vegan': [
      'chicken',
      'beef',
      'pork',
      'lamb',
      'turkey',
      'bacon',
      'ham',
      'fish',
      'salmon',
      'tuna',
      'egg',
      'milk',
      'cheese',
      'butter',
      'cream',
      'honey'
    ],
    'Gluten-Free': ['flour', 'wheat', 'barley', 'rye', 'pasta', 'bread'],
    'Dairy-Free': ['milk', 'cheese', 'butter', 'cream', 'yogurt'],
    'Keto': ['sugar', 'flour', 'rice', 'pasta', 'bread', 'potato'],
  };

  const HealthProfileEntity({
    this.dietaryPreferences = const [],
    this.healthConditions = const [],
    this.dailyCalorieTarget = 2000,
  });

  @override
  List<Object?> get props =>
      [dietaryPreferences, healthConditions, dailyCalorieTarget];

  HealthProfileEntity copyWith({
    List<String>? dietaryPreferences,
    List<String>? healthConditions,
    int? dailyCalorieTarget,
  }) {
    return HealthProfileEntity(
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      healthConditions: healthConditions ?? this.healthConditions,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
    );
  }

  Map<String, dynamic> toMap() => {
        'dietaryPreferences': dietaryPreferences,
        'healthConditions': healthConditions,
        'dailyCalorieTarget': dailyCalorieTarget,
      };

  factory HealthProfileEntity.fromMap(Map<String, dynamic> map) =>
      HealthProfileEntity(
        dietaryPreferences: List<String>.from(map['dietaryPreferences'] ?? []),
        healthConditions: List<String>.from(map['healthConditions'] ?? []),
        dailyCalorieTarget: map['dailyCalorieTarget'] as int? ?? 2000,
      );
}
