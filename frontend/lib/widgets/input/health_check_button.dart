import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/providers/health_provider.dart';

class HealthCheckButton extends ConsumerWidget {
  const HealthCheckButton({super.key});

   @override
   Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(healthStateProvider);
    final healthNotifier = ref.read(healthStateProvider.notifier);
    final theme = Theme.of(context);

    Color backgroundColor;
    Color iconColor;
    Widget icon;

    switch (status) {
      case HealthStatus.initial:
        backgroundColor = theme.colorScheme.onPrimary;
        iconColor = theme.colorScheme.primary;
        icon = const Icon(Icons.favorite_border);
        break;
      case HealthStatus.loading:
        backgroundColor = theme.colorScheme.onPrimary;
        iconColor = theme.colorScheme.primary;
        icon = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
        break;
      case HealthStatus.healthy:
        backgroundColor = theme.colorScheme.primary;
        iconColor = theme.colorScheme.onPrimary;
        icon = const Icon(Icons.check);
        break;
      case HealthStatus.unhealthy:
        backgroundColor = Colors.red;
        iconColor = theme.colorScheme.onPrimary;
        icon = const Icon(Icons.cancel);
        break;
    }

    return FloatingActionButton(
      onPressed: status == HealthStatus.loading ? null : () => healthNotifier.checkHealth(),
      mini: true,
      backgroundColor: backgroundColor,
      foregroundColor: iconColor,
      child: icon,
    );
  }
}

