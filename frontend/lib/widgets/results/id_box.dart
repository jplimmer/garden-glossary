import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/providers/plant_services_provider.dart';
import 'package:garden_glossary/providers/ui_state_provider.dart';
import 'package:garden_glossary/widgets/visual_effects/pulsing_text_widget.dart';

class IDBox extends ConsumerWidget {
  final String loadingText;
  
  const IDBox({
    super.key,
    this.loadingText = 'Identifying with PlantNet...',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plantServicesState = ref.watch(plantServicesProvider);
    final uiState = ref.watch(uiStateProvider);

    bool isLoading = plantServicesState.idState == IdentificationState.loading;
    bool loaded = plantServicesState.idState == IdentificationState.success;
    bool isError = plantServicesState.idState == IdentificationState.error;
    bool isExpanded = uiState.isIDBoxExpanded;
    int selectedIndex = plantServicesState.selectedMatchIndex;

    return GestureDetector(
      onTap: isLoading 
        ? null 
        : ref.read(uiStateProvider.notifier).toggleIDBoxExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: (!loaded)
                  ? PulsingText(
                    text: TextSpan(
                      text: loadingText,
                      style: const TextStyle(color: Colors.black),
                    ),
                    )
                  : plantServicesState.matches[selectedIndex],
                  // : (isError)
                  //   ? const Text(
                  //     'An error occurred.',
                  //     style: TextStyle(color: Colors.black),
                  //   )
                  //   : plantServicesState.matches[selectedIndex],
                ),
                if (loaded)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
              ],
            ),
            if (!isLoading && !isError && isExpanded) ...[
              const SizedBox(height: 8),
              const Divider(),
              ... plantServicesState.matches.asMap().entries.map((entry) {
                final index = entry.key;
                final match = entry.value;
                if (index == selectedIndex) return const SizedBox.shrink();

                return InkWell(
                  onTap: () {
                    ref.read(plantServicesProvider.notifier).selectMatch(index);
                    ref.read(uiStateProvider.notifier).toggleIDBoxExpanded();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: match,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

