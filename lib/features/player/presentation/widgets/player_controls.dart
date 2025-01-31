import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/audio_player_cubit.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                state.isShuffleEnabled ? Icons.shuffle : Icons.shuffle_outlined,
                color: state.isShuffleEnabled
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () => context.read<AudioPlayerCubit>().toggleShuffle(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () => context.read<AudioPlayerCubit>().previous(),
            ),
            FloatingActionButton(
              onPressed: () {
                if (state.status == AudioStatus.playing) {
                  context.read<AudioPlayerCubit>().pause();
                } else {
                  context.read<AudioPlayerCubit>().resume();
                }
              },
              child: Icon(
                state.status == AudioStatus.playing
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () => context.read<AudioPlayerCubit>().next(),
            ),
            IconButton(
              icon: Icon(
                state.isRepeatEnabled ? Icons.repeat : Icons.repeat_outlined,
                color: state.isRepeatEnabled
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () => context.read<AudioPlayerCubit>().toggleRepeat(),
            ),
          ],
        );
      },
    );
  }
}
