import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/virtual_fridge/data/datasources/fridge_local_datasource.dart';
import 'features/saved_recipes/data/datasources/saved_recipes_datasource.dart';
import 'features/health_profile/presentation/pages/health_profile_cubit.dart';
import 'features/saved_recipes/presentation/pages/saved_recipes_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.backgroundDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hive
  await Hive.initFlutter();
  await Hive.openBox('app_prefs');
  await FridgeLocalDataSource.init();
  await SavedRecipesDataSource.init();
  await HealthProfileCubit.initBox();

  // DI
  await initDependencies();

  runApp(const ZikolaApp());
}

class ZikolaApp extends StatelessWidget {
  const ZikolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SavedRecipesCubit>(
          create: (_) => sl<SavedRecipesCubit>()..loadSaved(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Zikola',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
