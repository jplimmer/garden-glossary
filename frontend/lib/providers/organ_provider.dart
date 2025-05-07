import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/models/organ.dart';

/// Provider for the currently selected plant organ
final organProvider = StateProvider<Organ>((ref) {
  // Default to flower as the initial selection
  return Organ.flower;
});

