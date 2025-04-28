class PlantServiceException implements Exception {
  final String message;
  const PlantServiceException(this.message);

  @override
  String toString() => message;
}