import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../media/presentation/widgets/cached_artwork.dart';
import '../cubit/audio_player_cubit.dart';
import 'base_player_style.dart';
import '../../domain/enums/playlist_source.dart';
import '../../domain/enums/player_style.dart';
import '../../../settings/data/providers/settings_provider.dart';
import '../widgets/style_popup_menu.dart';

class MinimalPlayerStyle extends BasePlayerStyle {
  MinimalPlayerStyle({
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onClose,
                ),
                const Spacer(),
                const StylePopupMenu(),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'artwork_${state.currentSong!.id}',
                  child: CachedArtwork(
                    id: state.currentSong!.id,
                    size: MediaQuery.of(context).size.width * 0.6,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  state.currentSong!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentSong!.artist ?? 'Bilinmeyen Sanatçı',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          _buildControls(context),
          const SizedBox(height: 32),
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
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
            thumbColor: colorScheme.primary,
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => context.read<AudioPlayerCubit>().previous(),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: colorScheme.onPrimary,
                  ),
                  onPressed: () =>
                      context.read<AudioPlayerCubit>().togglePlayPause(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => context.read<AudioPlayerCubit>().next(),
              ),
              IconButton(
                icon: Icon(
                  state.shuffleMode ? Icons.shuffle : Icons.shuffle_outlined,
                  color: state.shuffleMode ? colorScheme.primary : null,
                ),
                onPressed: () =>
                    context.read<AudioPlayerCubit>().toggleShuffle(),
              ),
              IconButton(
                icon: Icon(
                  switch (state.loopMode) {
                    LoopMode.off => Icons.repeat,
                    LoopMode.one => Icons.repeat_one,
                    LoopMode.all => Icons.repeat,
                  },
                  color: state.loopMode != LoopMode.off
                      ? colorScheme.primary
                      : null,
                ),
                onPressed: () =>
                    context.read<AudioPlayerCubit>().toggleLoopMode(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
