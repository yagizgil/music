import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../domain/enums/player_style.dart';
import '../../domain/enums/playlist_source.dart';
import '../cubit/audio_player_cubit.dart';

abstract class BasePlayerStyle extends StatelessWidget {
  final AudioPlayerState state;
  final List<SongModel> playlist;
  final String playlistName;
  final Function() onClose;
  final ColorScheme colorScheme;

  const BasePlayerStyle({
    super.key,
    required this.state,
    required this.playlist,
    required this.playlistName,
    required this.onClose,
    required this.colorScheme,
  });

  @protected
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
