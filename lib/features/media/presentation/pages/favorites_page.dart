import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/domain/enums/playlist_source.dart';
import '../widgets/sort_options_sheet.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCubit, MediaState>(
      builder: (context, mediaState) {
        if (mediaState.favorites.isEmpty) {
          return const Center(
            child: Text('Henüz favori şarkı eklenmemiş'),
          );
        }

        return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
          builder: (context, playerState) {
            return ListView.builder(
              itemCount: mediaState.favorites.length,
              itemBuilder: (context, index) {
                final song = mediaState.favorites[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        format: ArtworkFormat.JPEG,
                        size: 200,
                        quality: 75,
                        artworkQuality: FilterQuality.low,
                        artworkBorder: BorderRadius.zero,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Icon(
                          Icons.music_note,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Bilinmeyen Sanatçı'),
                  tileColor: playerState.currentSong?.id == song.id
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (playerState.currentSong?.id == song.id)
                        Icon(
                          Icons.equalizer,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(
                            Duration(milliseconds: song.duration ?? 0)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () => context.read<AudioPlayerCubit>().play(
                        song,
                        playlist: mediaState.favorites,
                        source: PlaylistSource.favorites,
                      ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlocBuilder<MediaCubit, MediaState>(
        builder: (context, state) {
          return SortOptionsSheet(
            sortType: state.sortType,
            sortOrder: state.sortOrder,
            onSortTypeChanged: (value) {
              context.read<MediaCubit>().changeSortType(value);
              Navigator.pop(context);
            },
            onSortOrderChanged: (order) {
              context.read<MediaCubit>().toggleSortOrder();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
