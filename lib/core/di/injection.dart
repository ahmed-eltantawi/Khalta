import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

// Features - Search
import '../../features/search/data/datasources/meal_remote_datasource.dart';
import '../../features/search/data/repositories/meal_repository_impl.dart';
import '../../features/search/domain/repositories/meal_repository.dart';
import '../../features/search/domain/usecases/meal_usecases.dart';

// Features - Virtual Fridge
import '../../features/virtual_fridge/data/datasources/fridge_local_datasource.dart';

// Features - Saved Recipes
import '../../features/saved_recipes/data/datasources/saved_recipes_datasource.dart';

// Presentation - BLoCs
import '../../features/search/presentation/blocs/search_bloc.dart';
import '../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../../features/saved_recipes/presentation/pages/saved_recipes_cubit.dart';
import '../../features/health_profile/presentation/pages/health_profile_cubit.dart';
import '../../features/home/presentation/cubits/home_cubit.dart';

  // Features - Home
import '../../features/home/domain/usecases/detect_ingredients_from_image.dart';
import '../../features/home/presentation/cubits/camera_cubit.dart';
import '../../features/home/presentation/cubits/voice_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // ── Data Sources ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<MealRemoteDataSource>(
    () => MealRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton(() => FridgeLocalDataSource());
  sl.registerLazySingleton(() => SavedRecipesDataSource());

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<MealRepository>(
    () => MealRepositoryImpl(sl<MealRemoteDataSource>()),
  );

  // ── Use Cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => SearchMealsByName(sl<MealRepository>()));
  sl.registerLazySingleton(() => SearchMealsByIngredient(sl<MealRepository>()));
  sl.registerLazySingleton(() => GetMealById(sl<MealRepository>()));
  sl.registerLazySingleton(() => GetRandomMeal(sl<MealRepository>()));
  sl.registerLazySingleton(() => GetRandomMeals(sl<MealRepository>()));
  sl.registerLazySingleton(() => GetAllCategories(sl<MealRepository>()));
  sl.registerLazySingleton(() => FilterMealsByCategory(sl<MealRepository>()));
  sl.registerLazySingleton(() => FilterMealsByArea(sl<MealRepository>()));
  sl.registerLazySingleton(() => FilterMealsByIngredients(sl<MealRepository>()));
  sl.registerLazySingleton(() => GetAllIngredients(sl<MealRepository>()));
  
  sl.registerLazySingleton(() => DetectIngredientsFromImage());

  // ── BLoCs / Cubits ────────────────────────────────────────────────────────
  sl.registerFactory(() => HomeCubit(
        getRandomMeals: sl<GetRandomMeals>(),
        getAllCategories: sl<GetAllCategories>(),
      ));
      
  sl.registerFactory(() => CameraCubit(sl<DetectIngredientsFromImage>()));
  sl.registerFactory(() => VoiceCubit());

  sl.registerFactory(() => SearchBloc(
        searchMealsByName: sl<SearchMealsByName>(),
        searchMealsByIngredient: sl<SearchMealsByIngredient>(),
        filterMealsByCategory: sl<FilterMealsByCategory>(),
        filterMealsByArea: sl<FilterMealsByArea>(),
        getAllCategories: sl<GetAllCategories>(),
        getAllIngredients: sl<GetAllIngredients>(),
        filterMealsByIngredients: sl<FilterMealsByIngredients>(),
      ));

  sl.registerFactory(() => FridgeBloc(
        dataSource: sl<FridgeLocalDataSource>(),
        searchMealsByIngredient: sl<SearchMealsByIngredient>(),
      ));

  sl.registerFactory(() => SavedRecipesCubit(sl<SavedRecipesDataSource>()));

  sl.registerFactory(() => HealthProfileCubit());
}
