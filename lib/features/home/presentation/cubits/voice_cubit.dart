import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class VoiceCubitState {}

class VoiceIdle extends VoiceCubitState {}

class VoiceInitializing extends VoiceCubitState {}

class VoiceListening extends VoiceCubitState {
  final String partialText;
  VoiceListening([this.partialText = '']);
}

class VoiceRecognized extends VoiceCubitState {
  final String rawText;
  final List<String> ingredients;
  VoiceRecognized(this.rawText, this.ingredients);
}

class VoiceError extends VoiceCubitState {
  final String message;
  VoiceError(this.message);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class VoiceCubit extends Cubit<VoiceCubitState> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  VoiceCubit() : super(VoiceIdle());

  Future<void> startListening() async {
    emit(VoiceInitializing());

    try {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onError: _onError,
          onStatus: _onStatus,
        );
      }

      if (!_isInitialized) {
        emit(VoiceError(
          'Speech recognition is not available.\n'
          'Please check microphone permissions in Settings.',
        ));
        return;
      }

      emit(VoiceListening());

      await _speech.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      emit(VoiceError('Failed to start voice recognition: $e'));
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (isClosed) return;

    if (result.finalResult) {
      final text = result.recognizedWords.trim();
      if (text.isEmpty) {
        emit(VoiceIdle());
        return;
      }
      final ingredients = _parseIngredients(text);
      emit(VoiceRecognized(text, ingredients));
    } else {
      // partial result — show live transcription
      emit(VoiceListening(result.recognizedWords));
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (isClosed) return;
    if (error.errorMsg == 'error_no_match' || error.errorMsg == 'error_speech_timeout') {
      // Nothing was recognized — just go back to idle
      emit(VoiceIdle());
    } else {
      emit(VoiceError('Recognition error: ${error.errorMsg}'));
    }
  }

  void _onStatus(String status) {
    if (isClosed) return;
    if (status == 'done' && state is VoiceListening) {
      final partial = (state as VoiceListening).partialText;
      if (partial.isNotEmpty) {
        // If we have partial text when it stops, treat it as final
        final ingredients = _parseIngredients(partial);
        emit(VoiceRecognized(partial, ingredients));
      }
    }
  }

  /// Parses a natural-language string like "chicken, rice and tomatoes" into
  /// individual ingredient names.
  List<String> _parseIngredients(String text) {
    // Normalize common spoken connectors
    String normalized = text
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\bwith\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\balso\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\bplus\b', caseSensitive: false), ',');

    // Remove filler words
    final fillers = {'um', 'uh', 'like', 'some', 'a', 'the', 'of', 'i', 'have', 'got'};

    final parts = normalized
        .split(RegExp(r'[,;]+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .map((phrase) {
          // Remove filler words from each phrase
          final words = phrase.split(RegExp(r'\s+'))
              .where((w) => !fillers.contains(w) && w.length > 1)
              .toList();
          return words.join(' ');
        })
        .where((s) => s.isNotEmpty && s.length > 1)
        .toList();

    return parts;
  }

  void stopListening() {
    _speech.stop();
    if (state is VoiceListening) {
      final partial = (state as VoiceListening).partialText;
      if (partial.isNotEmpty) {
        final ingredients = _parseIngredients(partial);
        emit(VoiceRecognized(partial, ingredients));
      } else {
        emit(VoiceIdle());
      }
    }
  }

  void reset() => emit(VoiceIdle());

  @override
  Future<void> close() {
    _speech.stop();
    _speech.cancel();
    return super.close();
  }
}
