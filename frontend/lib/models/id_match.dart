import 'package:flutter/material.dart';

class IDMatch extends StatelessWidget {
  final String species;
  final double score;
  final String commonNames;

  const IDMatch({
    super.key,
    required this.species,
    required this.score,
    required this.commonNames,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Colors.black, height: 1.5),
        children: <TextSpan>[
          const TextSpan(
            text: 'Species: ',
            style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: species),
          TextSpan(
            text: ' (${(score*100).toStringAsFixed(2)}% probability)',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const TextSpan(
            text: '\nCommon Names: ',
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(text: commonNames),
        ],
      ),
    );
  }
}

