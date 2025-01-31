import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

part of 'audio_player_cubit.dart';

enum AudioStatus { initial, loading, playing, paused, stopped, error }

class AudioPlayerState extends Equatable {
  final AudioStatus status;
  final SongModel? currentSong;
  final List<SongModel> currentPlaylist;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double currentPosition;
  final bool loopMode;
  final bool shuffleMode;
  final PlaylistSource playlistSource;
  final String? error;
  final String? albumId;

  const AudioPlayerState({
    this.status = AudioStatus.initial,
    this.currentSong,
    this.currentPlaylist = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.currentPosition = 0,
    this.loopMode = false,
    this.shuffleMode = false,
    this.playlistSource = PlaylistSource.allSongs,
    this.error,
    this.albumId,
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
    bool? loopMode,
    bool? shuffleMode,
    PlaylistSource? playlistSource,
    String? error,
    String? albumId,
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
      loopMode: loopMode ?? this.loopMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      playlistSource: playlistSource ?? this.playlistSource,
      error: error,
      albumId: albumId ?? this.albumId,
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
        loopMode,
        shuffleMode,
        playlistSource,
        error,
        albumId,
      ];
}
