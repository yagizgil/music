import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/audio_player_cubit.dart';

class PlayerSheet extends StatefulWidget {
  const PlayerSheet({super.key});

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet> {
  late DragStartDetails startVerticalDragDetails;
  late DragUpdateDetails updateVerticalDragDetails;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      builder: (context, state) {
        if (state.currentSong == null) return const SizedBox.shrink();

        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            // Burada thumbnail boyutunu ayarlayabiliriz
            return true;
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.1,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Sürükleme göstergesi
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Kapak resmi
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(20),
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: QueryArtworkWidget(
                              id: state.currentSong!.id,
                              type: ArtworkType.AUDIO,
                              artworkBorder: BorderRadius.circular(10),
                              nullArtworkWidget: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Şarkı bilgileri
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  state.currentSong!.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.currentSong!.artist ??
                                      'Bilinmeyen Sanatçı',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Oynatma kontrolleri
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 40,
                                onPressed: () {
                                  // Önceki şarkı
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  state.status == AudioStatus.playing
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                ),
                                iconSize: 70,
                                onPressed: () {
                                  final cubit =
                                      context.read<AudioPlayerCubit>();
                                  if (state.status == AudioStatus.playing) {
                                    cubit.pause();
                                  } else {
                                    cubit.resume();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                iconSize: 40,
                                onPressed: () {
                                  // Sonraki şarkı
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
