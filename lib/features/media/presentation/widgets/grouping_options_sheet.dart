import 'package:flutter/material.dart';
import '../../data/models/view_options.dart';

class GroupingOptionsSheet extends StatelessWidget {
  final Function(bool, GroupingMode) onGroupingChanged;

  const GroupingOptionsSheet({super.key, required this.onGroupingChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gruplandırma',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _GroupingChip(
                label: 'Alfabetik',
                onSelected: () =>
                    onGroupingChanged(true, GroupingMode.alphabetical),
              ),
              _GroupingChip(
                label: 'Sanatçı',
                onSelected: () =>
                    onGroupingChanged(true, GroupingMode.byArtist),
              ),
              _GroupingChip(
                label: 'Albüm',
                onSelected: () => onGroupingChanged(true, GroupingMode.byAlbum),
              ),
              _GroupingChip(
                label: 'Tarih',
                onSelected: () => onGroupingChanged(true, GroupingMode.byDate),
              ),
              _GroupingChip(
                label: 'Gruplandırma Yok',
                onSelected: () =>
                    onGroupingChanged(false, GroupingMode.alphabetical),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupingChip extends StatelessWidget {
  final String label;
  final VoidCallback onSelected;

  const _GroupingChip({
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onSelected,
    );
  }
}
