import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/domain/enums/playlist_source.dart';
import 'package:music_player/core/utils/duration_formatter.dart';
import 'package:music_player/core/extensions/list_item_style.dart';
import 'cached_artwork.dart';

class ScrollableMediaRow extends StatelessWidget {
  final List<SongModel> songs;
  final String title;
  final String playlistName;

  const ScrollableMediaRow({
    super.key,
    required this.songs,
    required this.title,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isPlaying = context.select((AudioPlayerCubit cubit) =>
                  cubit.state.currentSong?.id == song.id);

              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ListTile(
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
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                      fontWeight: isPlaying ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(
                    song.artist ?? 'Bilinmeyen Sanatçı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying
                          ? Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withOpacity(0.7)
                          : null,
                    ),
                  ),
                  trailing: Text(
                    DurationFormatter.format(
                        Duration(milliseconds: song.duration ?? 0)),
                    style: TextStyle(
                      color: isPlaying
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () {
                    context.read<AudioPlayerCubit>().playPlaylist(
                          songs,
                          source: PlaylistSource.allSongs,
                        );
                  },
                ).withListItemStyle(
                  context: context,
                  isPlaying: isPlaying,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
