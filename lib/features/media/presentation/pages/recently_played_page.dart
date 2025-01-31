import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/media_cubit.dart';
import '../widgets/media_list.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/domain/enums/playlist_source.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCubit, MediaState>(
      buildWhen: (previous, current) =>
          previous.recentlyPlayed != current.recentlyPlayed,
      builder: (context, mediaState) {
        if (mediaState.recentlyPlayed.isEmpty) {
          return const Center(
            child: Text('Henüz şarkı çalınmamış'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: mediaState.recentlyPlayed.length,
          itemBuilder: (context, index) {
            final song = mediaState.recentlyPlayed[index];

            return MediaListItem(
              key: ValueKey('song_${song.id}'),
              song: song,
              playlist: mediaState.recentlyPlayed,
              playlistName: 'Son Çalınanlar',
              onTap: () => context.read<AudioPlayerCubit>().play(
                    song,
                    playlist: mediaState.recentlyPlayed,
                    source: PlaylistSource.recentlyPlayed,
                  ),
            );
          },
        );
      },
    );
  }
}
