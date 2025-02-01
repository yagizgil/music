import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

part of 'audio_player_cubit.dart';

enum AudioStatus { initial, loading, playing, stopped, error }

class AudioPlayerState extends Equatable {
  final AudioStatus status;
  final SongModel? currentSong;
  final List<SongModel> currentPlaylist;
  final int? currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double currentPosition;
  final PlaylistSource playlistSource;
  final bool shuffleMode;
  final LoopMode loopMode;

  const AudioPlayerState({
    this.status = AudioStatus.initial,
    this.currentSong,
    this.currentPlaylist = const [],
    this.currentIndex,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.currentPosition = 0,
    this.playlistSource = PlaylistSource.allSongs,
    this.shuffleMode = false,
    this.loopMode = LoopMode.off,
  });

  AudioPlayerState copyWith({
    AudioStatus? status,
    SongModel? currentSong,
    List<SongModel>? currentPlaylist,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? currentPosition,
    PlaylistSource? playlistSource,
    bool? shuffleMode,
    LoopMode? loopMode,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      currentSong: currentSong ?? this.currentSong,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentPosition: currentPosition ?? this.currentPosition,
      playlistSource: playlistSource ?? this.playlistSource,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      loopMode: loopMode ?? this.loopMode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentSong,
        currentPlaylist,
        currentIndex,
        isPlaying,
        position,
        duration,
        currentPosition,
        playlistSource,
        shuffleMode,
        loopMode,
      ];
}
