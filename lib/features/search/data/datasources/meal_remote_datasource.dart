import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/meal_model.dart';
import '../models/category_model.dart';

abstract class MealRemoteDataSource {
  Future<List<MealModel>> searchMealsByName(String name);
  Future<List<MealModel>> searchMealsByIngredient(String ingredient);
  Future<MealModel?> getMealById(String id);
  Future<MealModel?> getRandomMeal();
  Future<List<CategoryModel>> getAllCategories();
  Future<List<MealModel>> filterMealsByCategory(String category);
  Future<List<MealModel>> filterMealsByArea(String area);
}

class MealRemoteDataSourceImpl implements MealRemoteDataSource {
  final Dio _dio;

  MealRemoteDataSourceImpl(this._dio);

  @override
  Future<List<MealModel>> searchMealsByName(String name) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchByName,
        queryParameters: {'s': name},
      );
      final meals = response.data['meals'];
      if (meals == null) return [];
      return (meals as List).map((m) => MealModel.fromJson(m)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to search meals');
    }
  }

  @override
  Future<List<MealModel>> searchMealsByIngredient(String ingredient) async {
    try {
      final response = await _dio.get(
        ApiConstants.filter,
        queryParameters: {'i': ingredient},
      );
      final meals = response.data['meals'];
      if (meals == null) return [];
      return (meals as List).map((m) => MealModel.fromFilterJson(m)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to filter by ingredient');
    }
  }

  @override
  Future<MealModel?> getMealById(String id) async {
    try {
      final response = await _dio.get(
        ApiConstants.lookupById,
        queryParameters: {'i': id},
      );
      final meals = response.data['meals'];
      if (meals == null || (meals as List).isEmpty) return null;
      return MealModel.fromJson(meals[0]);
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get meal details');
    }
  }

  @override
  Future<MealModel?> getRandomMeal() async {
    try {
      final response = await _dio.get(ApiConstants.random);
      final meals = response.data['meals'];
      if (meals == null || (meals as List).isEmpty) return null;
      return MealModel.fromJson(meals[0]);
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get random meal');
    }
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final categories = response.data['categories'];
      if (categories == null) return [];
      return (categories as List).map((c) => CategoryModel.fromJson(c)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get categories');
    }
  }

  @override
  Future<List<MealModel>> filterMealsByCategory(String category) async {
    try {
      final response = await _dio.get(
        ApiConstants.filter,
        queryParameters: {'c': category},
      );
      final meals = response.data['meals'];
      if (meals == null) return [];
      return (meals as List).map((m) => MealModel.fromFilterJson(m)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to filter by category');
    }
  }

  @override
  Future<List<MealModel>> filterMealsByArea(String area) async {
    try {
      final response = await _dio.get(
        ApiConstants.filter,
        queryParameters: {'a': area},
      );
      final meals = response.data['meals'];
      if (meals == null) return [];
      return (meals as List).map((m) => MealModel.fromFilterJson(m)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to filter by area');
    }
  }
}
