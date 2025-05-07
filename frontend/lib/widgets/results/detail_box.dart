import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/providers/settings_provider.dart';
import 'package:garden_glossary/providers/plant_services_provider.dart';
import 'package:garden_glossary/providers/ui_state_provider.dart';
import 'package:garden_glossary/models/plant_details.dart';
import 'package:garden_glossary/utils/text_utils.dart';
import 'package:garden_glossary/widgets/visual_effects/pulsing_text_widget.dart';
import 'package:garden_glossary/widgets/visual_effects/streaming_text_widget.dart';

class DetailBox extends ConsumerWidget {
  const DetailBox({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers to rebuild when they change
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final plantServicesState = ref.watch(plantServicesProvider);

    bool isLoading = plantServicesState.detailsState == DetailsFetchState.loading;
    final bool enableTextStreaming = plantServicesState.detailsState == DetailsFetchState.success && settings.textStreamingEffect;

    if (enableTextStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.watch(uiStateProvider.notifier).startTextStreaming();
      });
    }

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            PulsingText(
              text: TextSpan(
                text: plantServicesState.detailsLoadingText,
                style: const TextStyle(color: Colors.black),
              ),
            )
          else if (plantServicesState.details != null) ...[
            StreamingTextWidget(
              fullText: PlantDetailsWidget(details: plantServicesState.details!).getFullTextSpan(),
              streaming: enableTextStreaming,
              onStreamingComplete: () => ref.read(uiStateProvider.notifier).stopTextStreaming(),
            ),
            Consumer(
              builder: (context, ref, _) {
                final uiState = ref.watch(uiStateProvider);
                if (plantServicesState.detailsSource != null && !uiState.isTextStreaming) {
                  return Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Source: ${plantServicesState.detailsSource}',
                        style: const TextStyle(
                          color: Colors.black,
                          height: 1.0,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
            ),   
          ]
          else
            const Text.rich(
              TextSpan(
                text: 'No details found',
                style: TextStyle(
                  color: Colors.black,
                  height: 1.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
        ],
      ),
    );
  }
}

class PlantDetailsWidget extends StatelessWidget {
  final PlantDetails details;
  
  const PlantDetailsWidget({
    super.key,
    required this.details,
  });
  
  TextSpan getFullTextSpan() {
    return TextSpan(
      style: const TextStyle(color: Colors.black, height: 1.5),
      children: [
        // Cultivation tips + pruning
        buildTextWithLink(details.cultivationTips),
        const TextSpan(text: '\n'),
        buildTextWithLink(details.pruning),
        const TextSpan(text: '\n'),
        
        // Size
        const TextSpan(
          text: '\nPlant Size:\n',
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        TextSpan(text: 'Height: ${details.size.height}\n'),
        TextSpan(text: 'Spread: ${details.size.spread}\n'),
        
        // Growing conditions
        const TextSpan(
          text: '\nGrowing conditions:\n',
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        TextSpan(
          text: 'Soil type(s): ${details.soil.types.join(", ")}\n'
          'Moisture: ${details.soil.moisture.join(", ")}\n'
          'pH levels: ${details.soil.phLevels.join(", ")}\n'
        ),
        
        // Position
        const TextSpan(
          text: '\nPosition:\n',
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        TextSpan(
          text: 'Sunlight: ${details.position.sun.join(", ")}\n'
          'Aspect: ${details.position.aspect}\n'
          'Exposure: ${details.position.exposure}\n'
        ),
        
        // Hardiness
        const TextSpan(
          text: '\nHardiness: ',
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        TextSpan(text: '${details.hardiness}\n'),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Text.rich(getFullTextSpan());
  }
}

