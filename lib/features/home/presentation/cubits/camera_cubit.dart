import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/detect_ingredients_from_image.dart';

abstract class CameraCubitState {}

class CameraIdle extends CameraCubitState {}
class CameraScanning extends CameraCubitState {}
class CameraIngredientsDetected extends CameraCubitState {
  final List<String> ingredients;
  CameraIngredientsDetected(this.ingredients);
}
class CameraError extends CameraCubitState {
  final String message;
  CameraError(this.message);
}

class CameraCubit extends Cubit<CameraCubitState> {
  final DetectIngredientsFromImage detectIngredients;

  CameraCubit(this.detectIngredients) : super(CameraIdle());

  Future<void> scanImage(String path) async {
    emit(CameraScanning());
    try {
      final ingredients = await detectIngredients(path);
      emit(CameraIngredientsDetected(ingredients));
    } catch (e) {
      emit(CameraError('Failed to analyze image. Please try again.'));
    }
  }

  void reset() => emit(CameraIdle());
}
