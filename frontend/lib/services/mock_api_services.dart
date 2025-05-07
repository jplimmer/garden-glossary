import 'dart:async';

class MockIdentificationService {
  Future<Map<String, dynamic>> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'matches': {
        '0': {
          'species': 'Tulipa gesneriana', 
          'genus': 'Tulipa', 
          'score': 0.85094, 
          'commonNames': ["Didier's tulip", 'Garden tulip', 'Tulip'], 
          'imageUrls': [
            'https://bs.plantnet.org/image/m/105f50eca75670385b2d34a44568d8139a9266d6', 
            'https://bs.plantnet.org/image/m/8e11ba4efc2223273ce96551ee8a5565c3c9b498', 
            'https://bs.plantnet.org/image/m/e43307f18754e641f18da70fa87606a8b4d7f207'
          ],
        }, 
        '1': {
          'species': 'Tulipa kaufmanniana', 
          'genus': 'Tulipa', 
          'score': 0.0202, 
          'commonNames': ['Water-lily tulip', "Kaufmann's Tulip", 'Alpine Tulip'], 
          'imageUrls': [
            'https://bs.plantnet.org/image/m/baca155a9fd406770004aefb265236b97b6a362c', 
            'https://bs.plantnet.org/image/m/ebe233f4db9b4248014fe677e0a9a3bf314f0f78', 
            'https://bs.plantnet.org/image/m/ca9ca876a22cff9a9024705bc56443587b6a8219'
          ],
        }, 
        '2': {
          'species': 'Tulipa fosteriana', 
          'genus': 'Tulipa', 
          'score': 0.01001, 
          'commonNames': [], 
          'imageUrls': [
            'https://bs.plantnet.org/image/m/8d58122cfc8adbbe5682cee72f49727b9176c4f1', 
            'https://bs.plantnet.org/image/m/e161956316b0476b0ade94784a87d8c7e8018844', 
            'https://bs.plantnet.org/image/m/edcccab0bf08fc419c35d832a9590df9b3ab386a'
          ],
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
        'sun': ['Full sun'],
        'aspect': 'South–facing or West–facing',
        'exposure': 'Sheltered',
      },
      'cultivation_tips': 'Plant in autumn, at a depth of 10-15cm (4-6in) in fertile, well-drained soil. Choose a sunny position, with protection from strong winds and excess winter wet. See <a href="https://www.rhs.org.uk/plants/tulip/growing-guide">tulip cultivation</a> for more details',
      'pruning': '<a href="https://www.rhs.org.uk/garden-jobs/deadheading-plants">Deadhead</a> after flowering and remove fallen petals',
    };
  }
}

