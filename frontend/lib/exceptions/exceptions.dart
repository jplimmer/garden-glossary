enum ErrorType {
  identification,
  details,
  network,
  general
}

class PlantIdentificationException implements Exception {
  final String message;
  const PlantIdentificationException(this.message);

  @override
  String toString() => message;
}

class PlantDetailsException implements Exception {
  final String message;
  const PlantDetailsException(this.message);

  @override
  String toString() => message;
}

class JSONParseException implements Exception {
  final String message;
  final dynamic originalError;
  final dynamic jsonData;

  JSONParseException(this.message, [this.originalError, this.jsonData]);

  @override
  String toString() {
    if (jsonData != null) {
      return '$message - Original error: $originalError - JSON Data: $jsonData';
    } else {
      return '$message - Original error: $originalError';
    }
  }
}