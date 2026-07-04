class ServerException implements Exception {
  final String message;
  const ServerException(
      {this.message = 'A server error occurred. Please try again.'});

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'A local storage error occurred.'});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(
      {this.message = 'No internet connection. Please check your network.'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when Gemini fails due to a temporary issue (e.g., 503 Unavailable)
/// and all retries/fallbacks have been exhausted.
class TransientGeminiException implements Exception {
  final String message;
  final String originalError;
  
  const TransientGeminiException({
    this.message = 'The AI service is currently unavailable. Please try again in a few minutes.',
    required this.originalError,
  });

  @override
  String toString() => 'TransientGeminiException: $message ($originalError)';
}

/// Thrown when Gemini fails due to a non-recoverable error 
/// (e.g., Invalid API key, quota exceeded, 400 Bad Request).
class PermanentGeminiException implements Exception {
  final String message;
  final String originalError;

  const PermanentGeminiException({
    this.message = 'The AI service encountered a permanent error.',
    required this.originalError,
  });

  @override
  String toString() => 'PermanentGeminiException: $message ($originalError)';
}
