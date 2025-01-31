import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:typed_data';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../../media/presentation/cubit/media_cubit.dart';
import 'particle_effect_painter.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          _isDragging = true;
          _dragOffset = 0;
        });
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
          // Yukarı doğru sürükleme için negatif değer kontrol ediyoruz
          if (_dragOffset < -100) {
            _openPlayerPage(context);
          }
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset < -50 && details.primaryVelocity! < -800) {
          _openPlayerPage(context);
        }
        setState(() {
          _dragOffset = 0;
          _isDragging = false;
        });
      },
      onTap: () => _openPlayerPage(context),
      child: AnimatedContainer(
        duration: Duration(milliseconds: _isDragging ? 0 : 200),
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
          buildWhen: (previous, current) =>
              previous.currentSong != current.currentSong ||
              previous.isPlaying != current.isPlaying ||
              previous.position != current.position ||
              previous.duration != current.duration,
          builder: (context, state) {
            if (state.currentSong == null) return const SizedBox.shrink();

            return Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Progress bar'ı StreamBuilder ile güncelle
                  StreamBuilder<Duration>(
                    stream: context
                        .read<AudioPlayerCubit>()
                        .audioPlayer
                        .positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = state.duration;

                      return ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                Theme.of(context).colorScheme.surface,
                              ],
                              stops: [
                                position.inMilliseconds /
                                    duration.inMilliseconds,
                                position.inMilliseconds /
                                    duration.inMilliseconds,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Hero(
                          tag: 'artwork_${state.currentSong!.id}',
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(
                                    Icons.music_note,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.currentSong!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.currentSong!.artist ??
                                    'Bilinmeyen Sanatçı',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Material(
                          type: MaterialType.transparency,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                onPressed: () =>
                                    context.read<AudioPlayerCubit>().previous(),
                              ),
                              IconButton(
                                icon: Icon(
                                  state.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                onPressed: () {
                                  context
                                      .read<AudioPlayerCubit>()
                                      .togglePlayPause();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                onPressed: () =>
                                    context.read<AudioPlayerCubit>().next(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPlayerPage(BuildContext context) {
    final audioPlayerCubit = context.read<AudioPlayerCubit>();
    final state = audioPlayerCubit.state;

    // Debug için state'i kontrol edelim
    print('Mini Player State before navigation: $state');

    if (state.currentSong == null) {
      print('Current song is null in mini player!');
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MultiBlocProvider(
          providers: [
            BlocProvider.value(value: audioPlayerCubit),
            BlocProvider.value(value: context.read<MediaCubit>()),
          ],
          child: PlayerPage(
            playlist: state.currentPlaylist,
            playlistName: 'Şimdi Çalıyor',
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
