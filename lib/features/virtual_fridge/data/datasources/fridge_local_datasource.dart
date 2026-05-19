import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/fridge_item_entity.dart';

class FridgeLocalDataSource {
  static const String _boxName = 'fridge_items';

  Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  List<FridgeItemEntity> getAll() {
    return _box.values
        .map((e) => FridgeItemEntity.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<void> add(FridgeItemEntity item) async {
    await _box.put(item.id, item.toMap());
  }

  Future<void> update(FridgeItemEntity item) async {
    await _box.put(item.id, item.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
