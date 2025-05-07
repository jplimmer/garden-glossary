import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/models/organ.dart';
import 'package:garden_glossary/providers/organ_provider.dart';

class OrganPicker extends ConsumerWidget {
  const OrganPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Organ selectedOrgan = ref.watch(organProvider);
    final int initialIndex = Organ.values.indexOf(selectedOrgan);
    final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: initialIndex);

    return CupertinoPicker(
      scrollController: scrollController,
      itemExtent: 28.0,
      onSelectedItemChanged: (int index) {
        ref.read(organProvider.notifier).state = Organ.values[index];
      },
      children: Organ.values.map((organ) {
        return Center(child: Text(organ.toString().split('.').last));
      }).toList(),
    );
  }
}

