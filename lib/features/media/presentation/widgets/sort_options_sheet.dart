import 'package:flutter/material.dart';
import '../../data/models/sort_type.dart';

class SortOptionsSheet extends StatelessWidget {
  final MediaSortType sortType;
  final SortOrder sortOrder;
  final Function(MediaSortType) onSortTypeChanged;
  final Function(SortOrder) onSortOrderChanged;

  const SortOptionsSheet({
    super.key,
    required this.sortType,
    required this.sortOrder,
    required this.onSortTypeChanged,
    required this.onSortOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Sıralama',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            title: const Text('İsme Göre'),
            leading: const Icon(Icons.sort_by_alpha),
            trailing: Radio<MediaSortType>(
              value: MediaSortType.title,
              groupValue: sortType,
              onChanged: (value) => onSortTypeChanged(value!),
            ),
            tileColor: sortType == MediaSortType.title
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3)
                : null,
          ),
          ListTile(
            title: const Text('Sanatçıya Göre'),
            leading: const Icon(Icons.person),
            trailing: Radio<MediaSortType>(
              value: MediaSortType.artist,
              groupValue: sortType,
              onChanged: (value) => onSortTypeChanged(value!),
            ),
            tileColor: sortType == MediaSortType.artist
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3)
                : null,
          ),
          ListTile(
            title: const Text('Süreye Göre'),
            leading: const Icon(Icons.timer),
            trailing: Radio<MediaSortType>(
              value: MediaSortType.duration,
              groupValue: sortType,
              onChanged: (value) => onSortTypeChanged(value!),
            ),
            tileColor: sortType == MediaSortType.duration
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3)
                : null,
          ),
          ListTile(
            title: const Text('Oluşturulma Tarihine Göre'),
            leading: const Icon(Icons.date_range),
            trailing: Radio<MediaSortType>(
              value: MediaSortType.dateAdded,
              groupValue: sortType,
              onChanged: (value) => onSortTypeChanged(value!),
            ),
            tileColor: sortType == MediaSortType.dateAdded
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3)
                : null,
          ),
          Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          ListTile(
            title: Text(
              sortOrder == SortOrder.ascending ? 'Artan' : 'Azalan',
            ),
            leading: Icon(
              sortOrder == SortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              onSortOrderChanged(
                sortOrder == SortOrder.ascending
                    ? SortOrder.descending
                    : SortOrder.ascending,
              );
            },
            tileColor:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}
