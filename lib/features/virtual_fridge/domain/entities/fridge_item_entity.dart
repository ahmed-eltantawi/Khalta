import 'package:equatable/equatable.dart';

class FridgeItemEntity extends Equatable {
  final String id;
  final String name;
  final String quantity;
  final String unit;
  final DateTime? expiryDate;
  final DateTime addedAt;
  final String? imageUrl;

  const FridgeItemEntity({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.addedAt,
    this.imageUrl,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return !isExpired && daysLeft <= 3;
  }

  @override
  List<Object?> get props => [id, name];

  FridgeItemEntity copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? addedAt,
    String? imageUrl,
  }) {
    return FridgeItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
    };
  }

  factory FridgeItemEntity.fromMap(Map<String, dynamic> map) {
    return FridgeItemEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as String? ?? '1',
      unit: map['unit'] as String? ?? 'piece',
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int)
          : null,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
