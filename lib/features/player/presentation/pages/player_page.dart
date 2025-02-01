import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/audio_player_cubit.dart';
import '../../../media/presentation/cubit/media_cubit.dart';
import '../../../settings/data/providers/settings_provider.dart';
import '../styles/player_style_factory.dart';

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
          final selectedStyle = context.watch<SettingsProvider>().playerStyle;

          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop();
              return false;
            },
            child: PlayerStyleFactory.create(
              style: selectedStyle,
              state: state,
              playlist: widget.playlist,
              playlistName: widget.playlistName,
              onClose: () => Navigator.of(context).pop(),
              colorScheme: colorScheme,
            ),
          );
        },
      ),
    );
  }
}
