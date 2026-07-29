import 'package:flutter/material.dart';
import '../../domain/entities/network_provider.dart';

/// Row of network choices. Auto-detected selection can be passed in; the user
/// can always override.
class NetworkSelector extends StatelessWidget {
  final NetworkProvider? selected;
  final ValueChanged<NetworkProvider> onChanged;
  const NetworkSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final n in NetworkProvider.values)
          ChoiceChip(
            label: Text(n.label),
            selected: selected == n,
            onSelected: (_) => onChanged(n),
          ),
      ],
    );
  }
}
