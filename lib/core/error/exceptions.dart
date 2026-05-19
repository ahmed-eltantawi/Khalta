class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'A server error occurred. Please try again.'});

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
  const NetworkException({this.message = 'No internet connection. Please check your network.'});

  @override
  String toString() => 'NetworkException: $message';
}
