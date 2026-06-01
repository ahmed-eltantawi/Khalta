import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/detect_ingredients_from_image.dart';

abstract class CameraCubitState {}

class CameraIdle extends CameraCubitState {}

class CameraScanning extends CameraCubitState {}

/// Emitted after detection — presents one ingredient at a time for confirmation.
class CameraIngredientConfirmation extends CameraCubitState {
  /// The ingredient currently being presented for confirmation.
  final String currentIngredient;

  /// Remaining ingredients still to be confirmed (excludes current).
  final List<String> remaining;

  /// Ingredients the user has already accepted.
  final List<String> accepted;

  /// Total number of ingredients originally detected.
  final int totalDetected;

  /// Path to the captured image (for preview).
  final String imagePath;

  CameraIngredientConfirmation({
    required this.currentIngredient,
    required this.remaining,
    required this.accepted,
    required this.totalDetected,
    required this.imagePath,
  });
}

/// Emitted when the user has finished reviewing all ingredients.
class CameraConfirmationComplete extends CameraCubitState {
  /// The final list of ingredients the user accepted.
  final List<String> acceptedIngredients;
  CameraConfirmationComplete(this.acceptedIngredients);
}

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

  List<String> _pendingIngredients = [];
  List<String> _acceptedIngredients = [];
  int _totalDetected = 0;
  String _imagePath = '';

  CameraCubit(this.detectIngredients) : super(CameraIdle());

  Future<void> scanImage(String path) async {
    emit(CameraScanning());
    _imagePath = path;
    try {
      final ingredients = await detectIngredients(path);
      if (ingredients.isEmpty) {
        // If nothing is detected, instead of failing, provide an empty string
        // so the user can still add an item manually via the confirmation UI.
        _totalDetected = 1;
        _pendingIngredients = [''];
        _acceptedIngredients = [];
        _showNextConfirmation();
        return;
      }
      _totalDetected = ingredients.length;
      _pendingIngredients = ingredients.toList();
      _acceptedIngredients = [];
      _showNextConfirmation();
    } catch (e) {
      emit(CameraError('Failed to analyze image: $e'));
    }
  }

  /// User confirmed the current ingredient — add it and advance.
  /// If [finalName] is provided, it overrides the detected name.
  void confirmIngredient([String? finalName]) {
    final currentState = state;
    if (currentState is CameraIngredientConfirmation) {
      final nameToAdd = (finalName != null && finalName.trim().isNotEmpty)
          ? finalName.trim()
          : currentState.currentIngredient;

      // Only add if it's not entirely empty
      if (nameToAdd.isNotEmpty) {
        _acceptedIngredients.add(nameToAdd);
      }
      _showNextConfirmation();
    }
  }

  /// User skipped the current ingredient — advance without adding.
  void skipIngredient() {
    if (state is CameraIngredientConfirmation) {
      _showNextConfirmation();
    }
  }

  void _showNextConfirmation() {
    if (_pendingIngredients.isEmpty) {
      emit(CameraConfirmationComplete(List.unmodifiable(_acceptedIngredients)));
      return;
    }
    final next = _pendingIngredients.removeAt(0);
    emit(CameraIngredientConfirmation(
      currentIngredient: next,
      remaining: List.unmodifiable(_pendingIngredients),
      accepted: List.unmodifiable(_acceptedIngredients),
      totalDetected: _totalDetected,
      imagePath: _imagePath,
    ));
  }

  void reset() {
    _pendingIngredients = [];
    _acceptedIngredients = [];
    _totalDetected = 0;
    _imagePath = '';
    emit(CameraIdle());
  }
}
