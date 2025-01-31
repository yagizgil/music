import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';
import '../widgets/media_list.dart';
import '../widgets/cached_artwork.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/domain/enums/playlist_source.dart';

class MostPlayedPage extends StatelessWidget {
  const MostPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCubit, MediaState>(
      buildWhen: (previous, current) =>
          previous.playCount != current.playCount ||
          previous.songs != current.songs,
      builder: (context, mediaState) {
        if (mediaState.playCount.isEmpty) {
          return const Center(
            child: Text('Henüz şarkı çalınmamış'),
          );
        }

        final sortedSongs = mediaState.songs
            .where((song) => mediaState.playCount.containsKey(song.id))
            .toList()
          ..sort((a, b) => (mediaState.playCount[b.id] ?? 0)
              .compareTo(mediaState.playCount[a.id] ?? 0));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: sortedSongs.length,
          itemBuilder: (context, index) {
            final song = sortedSongs[index];
            final playCount = mediaState.playCount[song.id] ?? 0;

            return MediaListItem(
              key: ValueKey('song_${song.id}'),
              song: song,
              playlist: sortedSongs,
              playlistName: 'En Çok Çalınanlar',
              subtitle:
                  '${song.artist ?? 'Bilinmeyen Sanatçı'} • $playCount kez',
              onTap: () => context.read<AudioPlayerCubit>().play(
                    song,
                    playlist: mediaState.songs,
                    source: PlaylistSource.mostPlayed,
                  ),
            );
          },
        );
      },
    );
  }
}
