import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../media/presentation/widgets/cached_artwork.dart';
import '../../../media/presentation/cubit/media_cubit.dart';
import '../cubit/audio_player_cubit.dart';
import '../../domain/enums/playlist_source.dart';
import 'base_player_style.dart';

class OriginalPlayerStyle extends BasePlayerStyle {
  OriginalPlayerStyle({
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.8),
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            children: [
              _buildMainPage(context),
              _buildPlaylistPage(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainPage(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 50) {
          onClose();
        }
      },
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.expand_more),
                    color: Colors.white,
                    onPressed: onClose,
                  ),
                  Expanded(
                    child: Text(
                      playlistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      context.watch<MediaCubit>().isFavorite(state.currentSong!)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    color: Colors.white,
                    onPressed: () => context
                        .read<MediaCubit>()
                        .toggleFavorite(state.currentSong!),
                  ),
                ],
              ),
            ),
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
                          color: Colors.white,
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
                          color: Colors.white70,
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
              Text(
                formatDuration(state.position),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                formatDuration(state.duration),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colorScheme.secondary,
            inactiveTrackColor: colorScheme.secondary.withOpacity(0.3),
            thumbColor: colorScheme.secondary,
            trackHeight: 4,
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
                color: state.shuffleMode ? colorScheme.secondary : Colors.white,
              ),
              onPressed: () => context.read<AudioPlayerCubit>().toggleShuffle(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded,
                  color: Colors.white, size: 40),
              onPressed: () => context.read<AudioPlayerCubit>().previous(),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  state.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  size: 64,
                ),
                color: colorScheme.onSecondary,
                onPressed: () =>
                    context.read<AudioPlayerCubit>().togglePlayPause(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded,
                  color: Colors.white, size: 40),
              onPressed: () => context.read<AudioPlayerCubit>().next(),
            ),
            IconButton(
              icon: Icon(
                switch (state.loopMode) {
                  LoopMode.off => Icons.repeat,
                  LoopMode.one => Icons.repeat_one,
                  LoopMode.all => Icons.repeat,
                },
                color: state.loopMode != LoopMode.off
                    ? colorScheme.secondary
                    : Colors.white,
              ),
              onPressed: () =>
                  context.read<AudioPlayerCubit>().toggleLoopMode(),
            ),
          ],
        ),
      ],
    );
  }
}
