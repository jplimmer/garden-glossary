import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/providers/settings_provider.dart';

class SettingsOverlay extends ConsumerWidget {
  const SettingsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const Divider(),

            // Save image setting
            SwitchListTile(
              title: Text('Save images', style: TextStyle(color: theme.colorScheme.primary)),
              subtitle: const Text('Automatically save uploaded images to your device'),
              value: settings.saveImages,
              onChanged: (value) => settingsNotifier.setSaveImages(value),
            ),
            // Text streaming effect setting
            SwitchListTile(
              title: Text('Text streaming effect', style: TextStyle(color: theme.colorScheme.primary)),
              subtitle: const Text('Enable typewriter-like text animation for plant details'),
              value: settings.textStreamingEffect,
              onChanged: (value) => settingsNotifier.setTextStreamingEffect(value),
            ),
            // Save error logs option setting
            SwitchListTile(
              title: Text('Save logs option', style: TextStyle(color: theme.colorScheme.primary)),
              subtitle: const Text('Enable option to save logs if an error occurs'),
              value: settings.saveLogsOption,
              onChanged: (value) => settingsNotifier.setSaveLogsOption(value),
            ),

            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

