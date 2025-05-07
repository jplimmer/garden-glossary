import 'package:flutter/material.dart';
import 'package:garden_glossary/widgets/settings/settings_overlay.dart';
import 'package:garden_glossary/widgets/user_guide/user_guide_overlay.dart';

class HamburgerMenuButton extends StatelessWidget {
  const HamburgerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.menu,
        color: theme.colorScheme.primary,
      ),
      onSelected: (String choice) {
        switch (choice) {
          case 'User Guide':
            // Display User Guide
            showUserGuide(context);
            break;
          case 'Saved Logs':
            // Navigate to Saved Logs
            // print('Saved Logs selected');
            break;
          case 'Settings':
            // Display Settings
            showDialog(
              context: context,
              builder: (context) => const SettingsOverlay(),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 'User Guide',
            child: Text('User Guide', style: TextStyle(color: theme.colorScheme.primary)),
          ),
          PopupMenuItem(
            value: 'Saved Logs',
            child: Text('Saved Logs', style: TextStyle(color: theme.colorScheme.primary)),
          ),
          PopupMenuItem(
            value: 'Settings',
            child: Text('Settings', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ];
      },
      color: theme.cardColor
    );
  }
}

