class PlantIdentificationException implements Exception {
  final String message;
  const PlantIdentificationException(this.message);

  @override
  String toString() => message;
}