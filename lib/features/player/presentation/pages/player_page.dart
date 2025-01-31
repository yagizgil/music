import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:async';
import '../cubit/audio_player_cubit.dart';
import '../../../media/presentation/cubit/media_cubit.dart';
import '../../../media/presentation/widgets/cached_artwork.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../domain/enums/playlist_source.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

class PlayerPage extends StatefulWidget {
  final List<SongModel> playlist;
  final String playlistName;

  const PlayerPage({
    super.key,
    required this.playlist,
    required this.playlistName,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _liquidController = LiquidController();
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (previous, current) =>
          previous.currentSong != current.currentSong ||
          previous.isPlaying != current.isPlaying,
      builder: (context, state) {
        if (state.currentSong == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: LiquidSwipe(
            pages: [
              // Ana sayfa - şarkı detayları
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(1),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(context),
                      const Spacer(flex: 1),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          child: Hero(
                            tag: 'artwork_${state.currentSong!.id}',
                            child: CachedArtwork(
                              key: ValueKey(
                                  'player_artwork_${state.currentSong!.id}'),
                              id: state.currentSong!.id,
                              size: MediaQuery.of(context).size.width - 64,
                              memCacheWidth:
                                  (MediaQuery.of(context).size.width - 64)
                                      .toInt(),
                              memCacheHeight:
                                  (MediaQuery.of(context).size.width - 64)
                                      .toInt(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildSongInfo(state.currentSong!),
                      const Spacer(flex: 1),
                      _buildControls(context, state),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),

              // Playlist sayfası
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _liquidController.animateToPage(
                                page: 0,
                                duration: 400,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.playlistName,
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
                          itemCount: widget.playlist.length,
                          itemBuilder: (context, index) {
                            final song = widget.playlist[index];
                            final isPlaying = state.currentSong?.id == song.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isPlaying
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2)
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
                                    fontWeight:
                                        isPlaying ? FontWeight.bold : null,
                                    color: isPlaying
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
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
                                        playlist: widget.playlist,
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
              ),
            ],
            enableLoop: false,
            fullTransitionValue: 400,
            enableSideReveal: true,
            liquidController: _liquidController,
            waveType: WaveType.liquidReveal,
            positionSlideIcon: 0.5,
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset > 50 && details.primaryVelocity! > 800) {
          Navigator.maybePop(context);
        }
        setState(() {
          _dragOffset = 0;
          _isDragging = false;
        });
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
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
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.playlistName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        context.watch<MediaCubit>().isFavorite(context
                                .read<AudioPlayerCubit>()
                                .state
                                .currentSong!)
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      color: Colors.white,
                      onPressed: () => context
                          .read<MediaCubit>()
                          .toggleFavorite(context
                              .read<AudioPlayerCubit>()
                              .state
                              .currentSong!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(SongModel song) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            song.title,
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
            song.artist ?? 'Bilinmeyen Sanatçı',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
          buildWhen: (previous, current) =>
              previous.position != current.position ||
              previous.duration != current.duration,
          builder: (context, state) {
            final duration = state.duration;
            final position = state.position;

            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colorScheme.secondary,
                    inactiveTrackColor: colorScheme.secondary.withOpacity(0.3),
                    thumbColor: colorScheme.secondary,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: position.inMilliseconds
                        .toDouble()
                        .clamp(0.0, duration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      context
                          .read<AudioPlayerCubit>()
                          .seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
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
                onPressed: () {
                  context.read<AudioPlayerCubit>().togglePlayPause();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded,
                  color: Colors.white, size: 40),
              onPressed: () => context.read<AudioPlayerCubit>().next(),
            ),
            IconButton(
              icon: Icon(
                switch (context.select(
                    (AudioPlayerCubit cubit) => cubit.player.loopMode)) {
                  LoopMode.off => Icons.repeat,
                  LoopMode.one => Icons.repeat_one,
                  LoopMode.all => Icons.repeat,
                },
                color: switch (context.select(
                    (AudioPlayerCubit cubit) => cubit.player.loopMode)) {
                  LoopMode.off => Colors.white.withOpacity(0.5),
                  LoopMode.one => Colors.white,
                  LoopMode.all => Colors.white,
                },
              ),
              onPressed: () =>
                  context.read<AudioPlayerCubit>().toggleLoopMode(),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
