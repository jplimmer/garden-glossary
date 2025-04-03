class PlantDetails {
  final PlantSize size;
  final String hardiness;
  final Soil soil;
  final Position position;
  final String cultivationTips;
  final String pruning;

  PlantDetails({
    required this.size,
    required this.hardiness,
    required this.soil,
    required this.position,
    required this.cultivationTips,
    required this.pruning,
  });

  factory PlantDetails.fromJson(Map<String, dynamic> json) {
    return PlantDetails(
      size: PlantSize.fromJson(json['size']),
      hardiness: json['hardiness'] as String,
      soil: Soil.fromJson(json['soil']),
      position: Position.fromJson(json['position']),
      cultivationTips: json['cultivation_tips'] as String,
      pruning: json['pruning'] as String,
    );
  }
}

class PlantSize {
  final String height;
  final String spread;

  PlantSize({required this.height, required this.spread});

  factory PlantSize.fromJson(Map<String, dynamic> json) {
    return PlantSize(
      height: json['height'] as String,
      spread: json['spread'] as String,
    );
  }
}

class Soil {
  final List<String> types;
  final List<String> moisture;
  final List<String> phLevels;

  Soil({
    required this.types,
    required this.moisture,
    required this.phLevels,
  });

  factory Soil.fromJson(Map<String, dynamic> json) {
    return Soil(
      types: List<String>.from(json['types']),
      moisture: List<String>.from(json['moisture']),
      phLevels: List<String>.from(json['ph_levels']),
    );
  }
}

class Position {
  final List<String> sun;
  final String aspect;
  final String exposure;

  Position({
    required this.sun,
    required this.aspect,
    required this.exposure,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      sun: List<String>.from(json['sun']),
      aspect: json['aspect'] as String,
      exposure: json['exposure'] as String,
    );
  }
}

