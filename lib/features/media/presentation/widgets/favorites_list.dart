import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';
import 'package:music_player/features/player/presentation/pages/player_page.dart';
import 'package:music_player/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:music_player/core/utils/duration_formatter.dart';
import '../../data/models/sort_type.dart';
import 'sort_options_sheet.dart';
import 'cached_artwork.dart';
import 'package:music_player/core/extensions/list_item_style.dart';
import '../../../player/domain/enums/playlist_source.dart';

class FavoritesList extends StatefulWidget {
  const FavoritesList({super.key});

  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<MediaCubit, MediaState>(
      buildWhen: (previous, current) =>
          previous.favorites != current.favorites ||
          previous.pinnedFavorites != current.pinnedFavorites,
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = state.favorites;

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz favori medya yok',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              toolbarHeight: 48,
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: _buildOptionsBar(context, state),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = state.favorites[index];
                  return Builder(
                    builder: (context) {
                      final isPlaying = context.select<AudioPlayerCubit, bool>(
                        (cubit) => cubit.state.currentSong?.id == song.id,
                      );
                      final isPinned = state.pinnedFavorites.contains(song.id);

                      return ListTile(
                        contentPadding: ListItemStyle.listItemPadding,
                        leading: CachedArtwork(
                          key: ValueKey('artwork_${song.id}'),
                          id: song.id,
                          size: ListItemStyle.artworkSize,
                          borderRadius: ListItemStyle.artworkBorderRadius,
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlaying
                                ? colorScheme.onPrimaryContainer
                                : null,
                            fontWeight: isPlaying ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist ?? 'Bilinmeyen Sanatçı'} • ${DurationFormatter.format(Duration(milliseconds: song.duration ?? 0))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlaying
                                ? colorScheme.onPrimaryContainer
                                    .withOpacity(0.7)
                                : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: isPinned ? colorScheme.primary : null,
                              ),
                              onPressed: () => context
                                  .read<MediaCubit>()
                                  .togglePinFavorite(song.id),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _showRemoveDialog(context, song),
                            ),
                          ],
                        ),
                        onTap: () => context.read<AudioPlayerCubit>().play(
                              song,
                              playlist: favorites,
                              source: PlaylistSource.favorites,
                            ),
                      ).withListItemStyle(
                        context: context,
                        isPlaying: isPlaying,
                      );
                    },
                  );
                },
                childCount: favorites.length,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionsBar(BuildContext context, MediaState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
            tooltip: 'Sıralama',
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SortOptionsSheet(
        sortType: context.read<MediaCubit>().state.sortType,
        sortOrder: context.read<MediaCubit>().state.sortOrder,
        onSortTypeChanged: (type) {
          context.read<MediaCubit>().changeSortType(type);
          Navigator.pop(context);
        },
        onSortOrderChanged: (order) {
          context.read<MediaCubit>().toggleSortOrder();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context, SongModel song) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favorilerden Çıkar'),
        content: Text('${song.title} favorilerden çıkarılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (context.mounted) {
        context.read<MediaCubit>().toggleFavorite(song);
      }
    }
  }
}
