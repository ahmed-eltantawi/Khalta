import 'package:equatable/equatable.dart';

/// A structured ingredient extracted from a receipt or ingredient list image.
class ReceiptIngredient extends Equatable {
  final String name;
  final double? quantity;
  final String? unit;
  final double confidence;
  final bool isSelected;

  const ReceiptIngredient({
    required this.name,
    this.quantity,
    this.unit,
    required this.confidence,
    this.isSelected = true,
  });

  /// Whether this detection is low-confidence and should be highlighted.
  bool get isLowConfidence => confidence < 0.7;

  ReceiptIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? confidence,
    bool? isSelected,
  }) {
    return ReceiptIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      confidence: confidence ?? this.confidence,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Clear quantity (since copyWith can't set to null).
  ReceiptIngredient clearQuantity() {
    return ReceiptIngredient(
      name: name,
      quantity: null,
      unit: unit,
      confidence: confidence,
      isSelected: isSelected,
    );
  }

  /// Clear unit (since copyWith can't set to null).
  ReceiptIngredient clearUnit() {
    return ReceiptIngredient(
      name: name,
      quantity: quantity,
      unit: null,
      confidence: confidence,
      isSelected: isSelected,
    );
  }

  @override
  List<Object?> get props => [name, quantity, unit, confidence, isSelected];
}
