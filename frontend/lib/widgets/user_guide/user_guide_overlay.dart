import 'package:flutter/material.dart';

void showUserGuide(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
            return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                    'User Guide',
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold
                                    ),
                                ),
                            ),
                            const Divider(height: 1),
                            const Expanded(
                                child: SingleChildScrollView(
                                    child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: UserGuideContent(),
                                    ),
                                ),
                            ),
                            const Divider(height: 1),
                            TextButton(
                                child: const Text('Close'),
                                onPressed: () => Navigator.of(context).pop(),
                            ),
                        ],
                    ),
                ),
            );
        }
    );
}

class UserGuideContent extends StatelessWidget {
    const UserGuideContent({super.key});

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Introduction
                Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildRichText(
                        '<b>Garden Glossary</b> is your pocket plant expert that identifies plants from photos and provides '
                        'expert cultivation information from the Royal Horticultural Society (RHS) or Anthropic\'s Claude AI.',
                        16,
                    ),
                ),

                // How to Use Section
                Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                    children: [
                                        Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                            'How to Use',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            _buildNumberedListItem(
                                1,
                                'Use the <b>Camera</b> or <b>Gallery</b> button to select a photo of a plant.',
                                context,
                            ),
                            _buildNumberedListItem(
                                2,
                                'Choose the appropriate <b>organ</b> that is prominent in the image (e.g. flower, leaf), to help the model identify the plant.',
                                context,
                            ),
                            _buildNumberedListItem(
                                3,
                                'Click <b>Submit</b>.',
                                context,
                            ),
                            _buildNumberedListItem(
                                4,
                                'The app identifies the plant and displays up to 3 most likely matches with cultivation details from the RHS or Claude.',
                                context,
                            ),
                        ],
                    ),
                ),

                // Health Check Section
                Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                                children: [
                                    Icon(Icons.favorite_border, color: theme.colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Health-check',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                        ),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                                'The app has a health-check button in the bottom right corner that pings the backend to check if it is up and running.',
                                style: TextStyle(fontSize: 14),
                            ),
                            Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                ),
                                child: RichText(
                                    text: const TextSpan(
                                        style: TextStyle(fontSize: 14, color: Colors.black87),
                                        children: [
                                            TextSpan(
                                                text: 'Tip: ',
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                                text: 'When using the app for the first time after opening, press the health-check button before continuing with photo selection. This can help reduce the \'cold start\' time for the first use.',
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),

                // Identification Section
                Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                children: [
                                    Icon(Icons.eco_outlined, color: theme.colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                    'Identification',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                    ),
                                    ),
                                ],
                                ),
                            ),
                            const Text(
                                'The app uses the PlantNet API to identify plants from your photos:',
                                style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            _buildCheckListItem(
                                'Returns up to 3 most likely matches with confidence percentages',
                                context,
                            ),
                            _buildCheckListItem(
                                'Most likely match selected by default',
                                context,
                            ),
                            _buildCheckListItem(
                                'Selecting a different match updates the cultivation details',
                                context,
                            ),
                            Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            'Photo Viewer:',
                                            style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500
                                            ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildDotListItem(
                                            'Tap once to cycle through up to 3 reference photos',
                                            context,
                                        ),
                                        _buildDotListItem(
                                            'Double-tap to enlarge for detailed viewing',
                                            context,
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),

                // Details Section
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                                children: [
                                    Icon(Icons.local_florist_outlined, color: theme.colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Cultivation Details',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        const Text(
                            'Once a match is identified and selected, the app searches the RHS website for the species. If it can\'t find a close match for the species name, or key cultivation information is missing from the RHS website, it will fallback to Anthropic\'s Claude AI instead. The source of the information is displayed at the bottom.',
                            style: TextStyle(fontSize: 14),
                        ),
                    ],
                ),
            ],
        );
    }

    Widget _buildNumberedListItem(int number, String text, BuildContext context) {
        final theme = Theme.of(context);
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                    Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                        ),
                        child: Center(
                            child: Text(
                                number.toString(),
                                style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                ),
                            ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildRichText(text, 14),
                    ),
                ],
            )
        );
    }

    Widget _buildCheckListItem(String text, BuildContext context) {
        final theme = Theme.of(context);
        return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                text,
                style: const TextStyle(fontSize: 14),
                ),
            ),
            ],
        ),
        );
    }

    Widget _buildDotListItem(String text, BuildContext context) {
        return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
                ),
                child: const Center(
                child: Text(
                    '•',
                    style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                text,
                style: const TextStyle(fontSize: 14),
                ),
            ),
            ],
        ),
        );
    }

    Widget _buildRichText(String text, double fontSize) {
        // Simple parser for basic bold text in format <b>text</b>
        List<TextSpan> spans = [];
        
        RegExp exp = RegExp(r'<b>(.*?)</b>');
        int lastEnd = 0;
        
        for (RegExpMatch match in exp.allMatches(text)) {
        if (match.start > lastEnd) {
            spans.add(TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(fontSize: fontSize),
            ));
        }
        
        spans.add(TextSpan(
            text: match.group(1),
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ));
        
        lastEnd = match.end;
        }
        
        if (lastEnd < text.length) {
        spans.add(TextSpan(
            text: text.substring(lastEnd),
            style: TextStyle(fontSize: fontSize),
        ));
        }
        
        return RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.black87)));
    }
}

