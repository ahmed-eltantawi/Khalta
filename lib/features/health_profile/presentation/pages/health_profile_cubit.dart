import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../features/health_profile/domain/entities/health_profile_entity.dart';

class HealthProfileCubit extends Cubit<HealthProfileEntity> {
  static const _boxName = 'health_profile';
  static const _key = 'profile';

  HealthProfileCubit() : super(const HealthProfileEntity());

  static Future<void> initBox() async {
    await Hive.openBox(_boxName);
  }

  void loadProfile() {
    final box = Hive.box(_boxName);
    final raw = box.get(_key);
    if (raw != null) {
      emit(HealthProfileEntity.fromMap(Map<String, dynamic>.from(raw as Map)));
    }
  }

  Future<void> toggleDiet(String diet) async {
    final current = List<String>.from(state.dietaryPreferences);
    if (current.contains(diet)) {
      current.remove(diet);
    } else {
      current.add(diet);
    }
    await _save(state.copyWith(dietaryPreferences: current));
  }

  Future<void> toggleCondition(String condition) async {
    final current = List<String>.from(state.healthConditions);
    if (current.contains(condition)) {
      current.remove(condition);
    } else {
      current.add(condition);
    }
    await _save(state.copyWith(healthConditions: current));
  }

  Future<void> setCalorieTarget(int calories) async {
    await _save(state.copyWith(dailyCalorieTarget: calories));
  }

  Future<void> _save(HealthProfileEntity profile) async {
    final box = Hive.box(_boxName);
    await box.put(_key, profile.toMap());
    emit(profile);
  }
}
