import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/receipt_ingredient.dart';
import '../../domain/usecases/extract_ingredients_from_receipt.dart';
import '../../../../core/error/exceptions.dart';

// ─── States ─────────────────────────────────────────────────────────────────

abstract class ReceiptScanState extends Equatable {
  const ReceiptScanState();
  @override
  List<Object?> get props => [];
}

class ReceiptScanIdle extends ReceiptScanState {}

class ReceiptScanProcessing extends ReceiptScanState {}

class ReceiptScanRetrying extends ReceiptScanState {
  final int attempt;
  const ReceiptScanRetrying(this.attempt);

  @override
  List<Object?> get props => [attempt];
}

/// Emitted after detection — presents one ingredient at a time for confirmation.
class ReceiptIngredientConfirmation extends ReceiptScanState {
  /// The ingredient currently being presented for confirmation.
  final ReceiptIngredient currentIngredient;

  /// Remaining ingredients still to be confirmed (excludes current).
  final List<ReceiptIngredient> remaining;

  /// Ingredients the user has already accepted.
  final List<ReceiptIngredient> accepted;

  /// Total number of ingredients originally detected.
  final int totalDetected;

  /// Path to the captured image.
  final String imagePath;

  const ReceiptIngredientConfirmation({
    required this.currentIngredient,
    required this.remaining,
    required this.accepted,
    required this.totalDetected,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [
        currentIngredient,
        remaining,
        accepted,
        totalDetected,
        imagePath,
      ];
}

/// Emitted when the user has finished reviewing all ingredients.
class ReceiptConfirmationComplete extends ReceiptScanState {
  /// The final list of ingredients the user accepted.
  final List<ReceiptIngredient> acceptedIngredients;
  const ReceiptConfirmationComplete(this.acceptedIngredients);

  @override
  List<Object?> get props => [acceptedIngredients];
}

class ReceiptScanError extends ReceiptScanState {
  final String message;
  const ReceiptScanError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ──────────────────────────────────────────────────────────────────

class ReceiptScanCubit extends Cubit<ReceiptScanState> {
  final ExtractIngredientsFromReceipt extractIngredients;

  List<ReceiptIngredient> _pendingIngredients = [];
  List<ReceiptIngredient> _acceptedIngredients = [];
  int _totalDetected = 0;
  String _imagePath = '';

  ReceiptScanCubit(this.extractIngredients) : super(ReceiptScanIdle());

  /// Scan a receipt image and extract ingredients.
  Future<void> scanReceipt(String imagePath) async {
    emit(ReceiptScanProcessing());
    _imagePath = imagePath;
    try {
      final ingredients = await extractIngredients(
        imagePath,
        onRetry: (attempt) => emit(ReceiptScanRetrying(attempt)),
      );
      if (ingredients.isEmpty) {
        emit(const ReceiptScanError(
            'No food ingredients found in this image. Try a clearer photo of your receipt.'));
        return;
      }
      _totalDetected = ingredients.length;
      _pendingIngredients = ingredients.toList();
      _acceptedIngredients = [];
      _showNextConfirmation();
    } on TransientGeminiException catch (e) {
      emit(ReceiptScanError(e.message));
    } on PermanentGeminiException catch (e) {
      emit(ReceiptScanError(e.message));
    } catch (e) {
      emit(ReceiptScanError('Failed to scan receipt: $e'));
    }
  }

  /// User confirmed the current ingredient — add it and advance.
  /// If [editedIngredient] is provided, it overrides the detected values.
  void confirmIngredient([ReceiptIngredient? editedIngredient]) {
    final currentState = state;
    if (currentState is ReceiptIngredientConfirmation) {
      final itemToAdd = editedIngredient ?? currentState.currentIngredient;
      
      // Add if name is not empty
      if (itemToAdd.name.trim().isNotEmpty) {
        _acceptedIngredients.add(itemToAdd.copyWith(name: itemToAdd.name.trim()));
      }
      _showNextConfirmation();
    }
  }

  /// User skipped the current ingredient — advance without adding.
  void skipIngredient() {
    if (state is ReceiptIngredientConfirmation) {
      _showNextConfirmation();
    }
  }

  void _showNextConfirmation() {
    if (_pendingIngredients.isEmpty) {
      emit(ReceiptConfirmationComplete(List.unmodifiable(_acceptedIngredients)));
      return;
    }
    final next = _pendingIngredients.removeAt(0);
    emit(ReceiptIngredientConfirmation(
      currentIngredient: next,
      remaining: List.unmodifiable(_pendingIngredients),
      accepted: List.unmodifiable(_acceptedIngredients),
      totalDetected: _totalDetected,
      imagePath: _imagePath,
    ));
  }

  /// Reset back to idle state.
  void reset() {
    _pendingIngredients = [];
    _acceptedIngredients = [];
    _totalDetected = 0;
    _imagePath = '';
    emit(ReceiptScanIdle());
  }
}
