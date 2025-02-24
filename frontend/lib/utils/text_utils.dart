import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';


TextSpan buildTextWithLink(String htmlText) {
  // RegEx with named capturing groups for links
  final regExp = RegExp(r'(<a href="(?<url>[^"]+)">(?<linkText>[^<]+)</a>)');
  final matches = regExp.allMatches(htmlText);

  // Handle case with no links in text
  if (matches.isEmpty) {
    return TextSpan(text: htmlText);
  }
  
  // Loop through RegEx matches and split text accordigly
  List<TextSpan> spans = [];
  int lastEnd = 0;

  for (final match in matches) {
    final beforeLink = htmlText.substring(lastEnd, match.start);
    // Exract text before href
    if (beforeLink.isNotEmpty) {
      spans.add(TextSpan(text: beforeLink));
    }
    // Extract href from RegEx match groups
    final url = match.namedGroup('url') ?? '';
    final linkText = match.namedGroup('linkText');

    // Add clickable link as a TextSpan
    spans.add(
      TextSpan(
        text: linkText,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
      ),
    );

    // Update the last processed position in htmlText
    lastEnd = match.end;
  }
  
  // Add any remaining text after the last link
  if (lastEnd < htmlText.length) {
    spans.add(TextSpan(text: htmlText.substring(lastEnd)));
  }

  // Return all parts
  return TextSpan(
    style: const TextStyle(color: Colors.black, height: 1.5),
    children: spans,
  );
}

