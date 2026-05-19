import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

abstract class VoiceCubitState {}

class VoiceIdle extends VoiceCubitState {}
class VoiceListening extends VoiceCubitState {}
class VoiceRecognized extends VoiceCubitState {
  final String text;
  final List<String> ingredients;
  VoiceRecognized(this.text, this.ingredients);
}
class VoiceError extends VoiceCubitState {
  final String message;
  VoiceError(this.message);
}

class VoiceCubit extends Cubit<VoiceCubitState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  VoiceCubit() : super(VoiceIdle());

  Future<void> startListening() async {
    emit(VoiceListening());
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
             if (state is VoiceListening) {
                // If it stopped without error and we haven't emitted recognized
                stopListening(); 
             }
          }
        },
        onError: (errorNotification) {
          emit(VoiceError('Speech recognition error: ${errorNotification.errorMsg}'));
        },
      );

      if (available) {
        _speech.listen(
          onResult: (result) {
             if (result.finalResult) {
                _processText(result.recognizedWords);
             }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        emit(VoiceError('Speech recognition is not available on this device.'));
      }
    } catch (e) {
      emit(VoiceError('Failed to initialize speech recognition.'));
    }
  }

  void stopListening() {
    _speech.stop();
    // Revert to idle if nothing recognized
    if (state is VoiceListening) emit(VoiceIdle());
  }
  
  void _processText(String text) {
     if (text.isEmpty) {
        emit(VoiceIdle());
        return;
     }
     
     // very simple split
     final List<String> words = text.split(RegExp(r'\s+|,|and'))
         .map((e) => e.trim().toLowerCase())
         .where((e) => e.isNotEmpty && e.length > 2)
         .toList();
         
     emit(VoiceRecognized(text, words));
  }

  void reset() => emit(VoiceIdle());
}
