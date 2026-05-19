import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? description;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.description,
  });

  @override
  List<Object?> get props => [id, name];
}
