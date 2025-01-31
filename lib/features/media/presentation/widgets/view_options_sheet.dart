import 'package:flutter/material.dart';
import '../../data/models/view_options.dart';

class ViewOptionsSheet extends StatelessWidget {
  final ViewOptions options;
  final Function(ViewOptions) onOptionsChanged;

  const ViewOptionsSheet({
    super.key,
    required this.options,
    required this.onOptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Görünüm Ayarları',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildViewModeSection(context),
          const Divider(height: 32),
          _buildGroupingSection(context),
        ],
      ),
    );
  }

  Widget _buildViewModeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görünüm Modu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ViewMode>(
          segments: [
            ButtonSegment<ViewMode>(
              value: ViewMode.list,
              icon: const Icon(Icons.view_list),
              label: const Text('Liste'),
            ),
            ButtonSegment<ViewMode>(
              value: ViewMode.grid,
              icon: const Icon(Icons.grid_view),
              label: const Text('Grid'),
            ),
          ],
          selected: {options.viewMode},
          onSelectionChanged: (Set<ViewMode> selected) {
            onOptionsChanged(options.copyWith(viewMode: selected.first));
          },
        ),
      ],
    );
  }

  Widget _buildGroupingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gruplandırma',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Gruplandırmayı Etkinleştir'),
          value: options.enableGrouping,
          onChanged: (value) {
            onOptionsChanged(options.copyWith(enableGrouping: value));
          },
        ),
        if (options.enableGrouping) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GroupingMode.values.map((mode) {
              return ChoiceChip(
                label: Text(_getGroupingModeLabel(mode)),
                selected: options.groupingMode == mode,
                onSelected: (selected) {
                  if (selected) {
                    onOptionsChanged(options.copyWith(groupingMode: mode));
                  }
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _getGroupingModeLabel(GroupingMode mode) {
    switch (mode) {
      case GroupingMode.alphabetical:
        return 'Alfabetik';
      case GroupingMode.byDate:
        return 'Tarihe Göre';
      case GroupingMode.byArtist:
        return 'Sanatçıya Göre';
      case GroupingMode.byAlbum:
        return 'Albüme Göre';
    }
  }
}
