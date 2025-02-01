import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../media/presentation/widgets/cached_artwork.dart';
import '../cubit/audio_player_cubit.dart';
import 'base_player_style.dart';
import '../../domain/enums/playlist_source.dart';

class ClassicPlayerStyle extends BasePlayerStyle {
  ClassicPlayerStyle({
    super.key,
    required super.state,
    required super.playlist,
    required super.playlistName,
    required super.onClose,
    required super.colorScheme,
  });

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: PageView(
        controller: _pageController,
        children: [
          _buildMainPage(context),
          _buildPlaylistPage(context),
        ],
      ),
    );
  }

  Widget _buildMainPage(BuildContext context) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: onClose,
        ),
        title: Text(playlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () => _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Hero(
            tag: 'artwork_${state.currentSong!.id}',
            child: CachedArtwork(
              id: state.currentSong!.id,
              size: MediaQuery.of(context).size.width - 64,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  state.currentSong!.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentSong!.artist ?? 'Bilinmeyen Sanatçı',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildControls(context),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildPlaylistPage(BuildContext context) {
    return Container(
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      playlistName,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: playlist.length,
                itemBuilder: (context, index) {
                  final song = playlist[index];
                  final isPlaying = state.currentSong?.id == song.id;

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isPlaying
                          ? colorScheme.primary.withOpacity(0.2)
                          : null,
                    ),
                    child: ListTile(
                      leading: Hero(
                        tag: 'playlist_artwork_${song.id}',
                        child: CachedArtwork(
                          key: ValueKey(song.id),
                          id: song.id,
                          size: 48,
                          borderRadius: 8,
                          memCacheWidth: 48,
                          memCacheHeight: 48,
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isPlaying ? FontWeight.bold : null,
                          color: isPlaying ? colorScheme.primary : null,
                        ),
                      ),
                      subtitle: Text(
                        song.artist ?? 'Bilinmeyen Sanatçı',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        context.read<AudioPlayerCubit>().play(
                              song,
                              playlist: playlist,
                              source: PlaylistSource.allSongs,
                            );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(state.position)),
              Text(formatDuration(state.duration)),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
            thumbColor: colorScheme.primary,
            trackHeight: 2,
          ),
          child: Slider(
            value: state.position.inMilliseconds.toDouble(),
            max: state.duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              context
                  .read<AudioPlayerCubit>()
                  .seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                state.shuffleMode ? Icons.shuffle : Icons.shuffle_outlined,
                color: state.shuffleMode ? colorScheme.primary : null,
              ),
              onPressed: () => context.read<AudioPlayerCubit>().toggleShuffle(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 32,
              onPressed: () => context.read<AudioPlayerCubit>().previous(),
            ),
            FloatingActionButton(
              onPressed: () =>
                  context.read<AudioPlayerCubit>().togglePlayPause(),
              child: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 32,
              onPressed: () => context.read<AudioPlayerCubit>().next(),
            ),
            IconButton(
              icon: const Icon(Icons.repeat),
              color: state.loopMode != null ? colorScheme.primary : null,
              onPressed: () =>
                  context.read<AudioPlayerCubit>().toggleLoopMode(),
            ),
          ],
        ),
      ],
    );
  }
}
