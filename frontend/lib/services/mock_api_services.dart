import 'dart:async';

class MockIdentificationService {
  Future<Map<String, dynamic>> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'matches': {
        '0': {
          'species': 'Tulipa gesneriana',
          'genus': 'Tulipa',
          'score': 0.57689,
          'commonNames': ["Didier's tulip", 'Garden tulip', 'Tulip']
        },
        '1': {
          'species': 'Tulipa agenensis',
          'genus': 'Tulipa',
          'score': 0.16454,
          'commonNames': ['Eyed tulip', 'Common tulip', 'Tulip']
        },
        '2': {
          'species': 'Tulipa fosteriana',
          'genus': 'Tulipa',
          'score': 0.0089,
          'commonNames': []
        },
      },
    };
  }
}

class MockDetailsService {
  Future<Map<String, dynamic>> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'size': {
        'height': '0.1–0.5 metres', 
        'spread': '0.1–0.5 metres', 
        'time_to_height': '1 year'
      },
      'hardiness': 'H6: hardy in all of UK and northern Europe (-20 to -15)',
      'soil': {
        'types': ['Chalk', 'Clay', 'Loam', 'Sand'],
        'moisture': ['Moist but well–drained'],
        'ph_levels': ['Acid'],
      },
      'position': {
        'sun': 'Full sun',
        'aspect': 'South–facing or West–facing',
        'exposure': 'Sheltered',
      },
      'cultivation_tips': 'Plant in autumn, at a depth of 10-15cm (4-6in) in fertile, well-drained soil. Choose a sunny position, with protection from strong winds and excess winter wet. See <a href="https://www.rhs.org.uk/plants/tulip/growing-guide">tulip cultivation</a> for more details',
      'pruning': '<a href="https://www.rhs.org.uk/garden-jobs/deadheading-plants">Deadhead</a> after flowering and remove fallen petals',
    };
  }
}

