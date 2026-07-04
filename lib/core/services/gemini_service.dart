import 'dart:io';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// A production-ready service for interacting with Gemini AI.
/// Features:
/// - Exponential backoff retries for transient errors (503, timeouts).
/// - Automatic fallback to a secondary model.
/// - Detailed error classification and logging.
class GeminiService {
  static const int _maxRetries = 3;
  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _fallbackModel = 'gemini-1.5-flash';

  final String _apiKey;

  GeminiService({String? apiKey}) : _apiKey = apiKey ?? ApiConstants.geminiApiKey;

  /// Generates content using the specified prompt and image part, applying 
  /// retries and fallback models if transient errors occur.
  ///
  /// [onRetry] is an optional callback triggered before each retry attempt.
  Future<String> generateContentWithRetry({
    required Iterable<Part> promptParts,
    GenerationConfig? generationConfig,
    Function(int attempt)? onRetry,
  }) async {
    final startTime = DateTime.now();

    try {
      // 1. Try Primary Model
      return await _executeWithRetry(
        modelName: _primaryModel,
        promptParts: promptParts,
        generationConfig: generationConfig,
        onRetry: onRetry,
      );
    } on TransientGeminiException catch (primaryError) {
      developer.log(
        'Primary model ($_primaryModel) failed after retries. Switching to fallback model ($_fallbackModel).',
        name: 'GeminiService',
        error: primaryError,
      );

      // 2. Try Fallback Model if primary completely failed due to transient issues
      try {
        return await _executeWithRetry(
          modelName: _fallbackModel,
          promptParts: promptParts,
          generationConfig: generationConfig,
          onRetry: onRetry,
        );
      } catch (fallbackError) {
        final duration = DateTime.now().difference(startTime);
        developer.log(
          'Fallback model ($_fallbackModel) also failed. Total duration: ${duration.inSeconds}s.',
          name: 'GeminiService',
          error: fallbackError,
        );
        // Throw the fallback error (which could be Transient or Permanent)
        rethrow;
      }
    } catch (e) {
      // Permanent errors from the primary model bubble up immediately.
      final duration = DateTime.now().difference(startTime);
      developer.log(
        'Permanent error encountered on primary model ($_primaryModel). Total duration: ${duration.inSeconds}s.',
        name: 'GeminiService',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> _executeWithRetry({
    required String modelName,
    required Iterable<Part> promptParts,
    GenerationConfig? generationConfig,
    Function(int attempt)? onRetry,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: generationConfig,
    );

    int attempt = 0;
    while (true) {
      final attemptStartTime = DateTime.now();
      try {
        if (attempt > 0) {
          developer.log('Attempt $attempt of $_maxRetries for model $modelName', name: 'GeminiService');
        }

        final response = await model.generateContent([
          Content.multi(promptParts)
        ]);

        final text = response.text?.trim();
        if (text == null) {
          throw GenerativeAIException('Gemini returned an empty or null response.');
        }

        if (attempt > 0) {
          developer.log('Success on attempt $attempt for model $modelName', name: 'GeminiService');
        }
        
        return text;

      } catch (e) {
        final duration = DateTime.now().difference(attemptStartTime);
        final isTransient = _isTransientError(e);

        developer.log(
          'Error on attempt ${attempt + 1} ($modelName) after ${duration.inMilliseconds}ms. Transient: $isTransient',
          name: 'GeminiService',
          error: e,
        );

        if (!isTransient) {
          // It's a permanent error (e.g., auth, quota, malformed request). 
          // Do not retry.
          throw PermanentGeminiException(
            message: 'The AI service encountered a permanent error.',
            originalError: e.toString(),
          );
        }

        // It is transient. Can we retry?
        if (attempt >= _maxRetries) {
          developer.log('Max retries ($_maxRetries) exhausted for model $modelName.', name: 'GeminiService');
          throw TransientGeminiException(
            message: 'The AI service is currently unavailable. Please try again in a few minutes.',
            originalError: e.toString(),
          );
        }

        // We can retry. Wait with exponential backoff.
        attempt++;
        if (onRetry != null) {
          onRetry(attempt);
        }

        // Delay: 2s, 4s, 8s...
        final delaySeconds = 1 << attempt; // 2^1=2, 2^2=4, 2^3=8
        developer.log('Waiting $delaySeconds seconds before retry...', name: 'GeminiService');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  /// Determines if an error is temporary and should be retried.
  bool _isTransientError(dynamic error) {
    if (error is SocketException || error is HttpException) {
      return true;
    }
    
    final errorString = error.toString().toLowerCase();

    // Specific HTTP statuses
    if (errorString.contains('503') || errorString.contains('504') || errorString.contains('502')) {
      return true;
    }

    // Google Generative AI specific strings
    if (errorString.contains('unavailable') || 
        errorString.contains('overloaded') ||
        errorString.contains('timeout') ||
        errorString.contains('internal server error')) {
      return true;
    }

    // Known permanent errors:
    // 400 Bad Request, 401 Unauthorized, 403 Forbidden, 429 Too Many Requests (Quota)
    if (errorString.contains('400') || 
        errorString.contains('401') || 
        errorString.contains('403') || 
        errorString.contains('429')) {
      return false;
    }

    // If we aren't sure, we treat it as permanent to avoid infinite failing loops,
    // though you could default to true if you prefer aggressive retrying.
    return false;
  }
}
