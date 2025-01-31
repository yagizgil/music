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
  final PageController _pageController = PageController();
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<AudioPlayerCubit>()),
        BlocProvider.value(value: context.read<MediaCubit>()),
      ],
      child: BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
        buildWhen: (previous, current) =>
            previous.currentSong != current.currentSong ||
            previous.isPlaying != current.isPlaying ||
            previous.shuffleMode != current.shuffleMode ||
            previous.loopMode != current.loopMode ||
            previous.position != current.position ||
            previous.duration != current.duration,
        builder: (context, state) {
          if (state.currentSong == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;

          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop();
              return false;
            },
            child: Scaffold(
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
                      _buildMainPage(context, state, colorScheme),
                      _buildPlaylistPage(context, state, colorScheme),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainPage(
      BuildContext context, AudioPlayerState state, ColorScheme colorScheme) {
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
                        context
                                .watch<MediaCubit>()
                                .isFavorite(state.currentSong!)
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
              Container(
                height: MediaQuery.of(context).size.width - 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Hero(
                  tag: 'artwork_${state.currentSong!.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: QueryArtworkWidget(
                          id: state.currentSong!.id,
                          type: ArtworkType.AUDIO,
                          format: ArtworkFormat.JPEG,
                          size: 1000,
                          quality: 100,
                          artworkQuality: FilterQuality.high,
                          artworkBorder: BorderRadius.zero,
                          artworkFit: BoxFit.cover,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            color: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.music_note,
                              color: colorScheme.onPrimaryContainer,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                          inactiveTrackColor:
                              colorScheme.secondary.withOpacity(0.3),
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
                      state.shuffleMode
                          ? Icons.shuffle
                          : Icons.shuffle_outlined,
                      color: state.shuffleMode
                          ? colorScheme.secondary
                          : Colors.white,
                    ),
                    onPressed: () =>
                        context.read<AudioPlayerCubit>().toggleShuffle(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white, size: 40),
                    onPressed: () =>
                        context.read<AudioPlayerCubit>().previous(),
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
                      state.loopMode ? Icons.repeat_one : Icons.repeat,
                      color: state.loopMode
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () =>
                        context.read<AudioPlayerCubit>().toggleLoopMode(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistPage(
      BuildContext context, AudioPlayerState state, ColorScheme colorScheme) {
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
                      state.playlistSource == PlaylistSource.allSongs
                          ? 'Tüm Şarkılar'
                          : state.playlistSource == PlaylistSource.favorites
                              ? 'Favoriler'
                              : state.playlistSource ==
                                      PlaylistSource.mostPlayed
                                  ? 'En Çok Çalınanlar'
                                  : state.playlistSource ==
                                          PlaylistSource.recentlyPlayed
                                      ? 'Son Çalınanlar'
                                      : widget.playlistName,
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
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.playlist.length,
                itemBuilder: (context, index) {
                  final song = widget.playlist[index];
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
                          nullArtworkWidget: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
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
                      onTap: () => context.read<AudioPlayerCubit>().play(
                            song,
                            playlist: state.currentPlaylist,
                            source: state.playlistSource,
                            albumId: state.albumId,
                          ),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
