import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'package:just_audio_background/just_audio_background.dart';
import '../../data/services/music_player_handler.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:rxdart/rxdart.dart';
import '../../../media/presentation/cubit/media_cubit.dart';
import 'dart:async'; // StreamSubscription için bu import gerekli
import '../../domain/enums/playlist_source.dart';

part 'audio_player_state.dart';

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final AudioPlayer audioPlayer;
  final MediaCubit mediaCubit;

  AudioPlayerCubit({
    required this.audioPlayer,
    required this.mediaCubit,
  }) : super(const AudioPlayerState()) {
    _setupListeners(); // Constructor'da dinleyicileri başlat
  }

  void _setupListeners() {
    // Player durumu dinleyicisi
    audioPlayer.playerStateStream.listen((playerState) {
      print(
          '🎵 Player durumu: ${playerState.processingState}, Playing: ${playerState.playing}');

      emit(state.copyWith(
        isPlaying: playerState.playing,
        status: _getStatusFromProcessingState(playerState.processingState),
      ));
    });

    // Şarkı değişim ve süre bilgilerini birlikte dinle
    Rx.combineLatest3<Duration?, Duration?, int?,
        ({Duration? duration, Duration? position, int? index})>(
      audioPlayer.durationStream,
      audioPlayer.positionStream,
      audioPlayer.currentIndexStream,
      (duration, position, index) => (
        duration: duration,
        position: position,
        index: index,
      ),
    ).listen((data) {
      if (data.index != null &&
          data.index! >= 0 &&
          data.index! < state.currentPlaylist.length) {
        final currentSong = state.currentPlaylist[data.index!];
        print('📑 Şarkı değişti: ${currentSong.title}');
        print('⏱️ Süre: ${data.duration?.inSeconds ?? 0} saniye');
        print('⏱️ Pozisyon: ${data.position?.inSeconds ?? 0} saniye');

        emit(state.copyWith(
          currentSong: currentSong,
          currentIndex: data.index,
          duration: data.duration ?? Duration.zero,
          position: data.position ?? Duration.zero,
          currentPosition: data.position?.inMilliseconds.toDouble() ?? 0,
        ));
      }
    });

    // Sequence durumu dinleyicisi
    audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        final currentItem = sequenceState.currentSource;
        if (currentItem != null) {
          final mediaItem = currentItem.tag as MediaItem;
          print('🎵 Çalan şarkı: ${mediaItem.title}');

          // Playlist durumunu güncelle
          emit(state.copyWith(
            shuffleMode: sequenceState.shuffleModeEnabled,
            loopMode: sequenceState.loopMode == LoopMode.one,
          ));
        }
      }
    });
  }

  void updatePlaybackState(PlayerState playerState) {
    emit(state.copyWith(
      isPlaying: playerState.playing,
      status: _getStatusFromProcessingState(playerState.processingState),
    ));
  }

  void updateCurrentSongIndex(int index) {
    if (index >= 0 && index < state.currentPlaylist.length) {
      emit(state.copyWith(
        currentSong: state.currentPlaylist[index],
        currentIndex: index,
      ));
    }
  }

  void updatePosition(Duration position) {
    emit(state.copyWith(
      position: position,
      currentPosition: position.inMilliseconds.toDouble(),
    ));
  }

  void updateDuration(Duration duration) {
    emit(state.copyWith(duration: duration));
  }

  void updatePlaylist(List<SongModel> playlist, int currentIndex) {
    emit(state.copyWith(
      currentPlaylist: playlist,
      currentSong: playlist[currentIndex],
      currentIndex: currentIndex,
    ));
  }

  Future<void> play(
    SongModel song, {
    required List<SongModel> playlist,
    required PlaylistSource source,
    String? albumId,
  }) async {
    try {
      final index = playlist.indexOf(song);
      if (index != -1) {
        await playPlaylist(songs: playlist, initialIndex: index);
        emit(state.copyWith(
          playlistSource: source,
          albumId: albumId,
        ));
      }
    } catch (e) {
      print('❌ Play hatası: $e');
    }
  }

  Future<void> playPlaylist({
    required List<SongModel> songs,
    required int initialIndex,
  }) async {
    try {
      print('🎵 Playlist yükleniyor (${songs.length} şarkı)');

      // Önce mevcut çalanı durdur
      await audioPlayer.stop();

      // Playlist'i hazırla
      final playlist = ConcatenatingAudioSource(
        children: songs
            .map((song) => AudioSource.uri(
                  Uri.parse(song.data),
                  tag: MediaItem(
                    id: song.id.toString(),
                    album: song.album ?? '',
                    title: song.title,
                    artist: song.artist ?? 'Bilinmeyen Sanatçı',
                    duration: Duration(milliseconds: song.duration ?? 0),
                  ),
                ))
            .toList(),
      );

      // Playlist'i ayarla
      await audioPlayer.setAudioSource(
        playlist,
        initialIndex: initialIndex,
      );

      // State'i güncelle
      updatePlaylist(songs, initialIndex);

      // Çalmaya başla
      await audioPlayer.play();

      print('✅ Playlist başlatıldı: ${songs[initialIndex].title}');
    } catch (e) {
      print('❌ PlayPlaylist hatası: $e');
      emit(state.copyWith(
        status: AudioStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (audioPlayer.playing) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } catch (e) {
      print('❌ TogglePlayPause hatası: $e');
    }
  }

  Future<void> next() async {
    try {
      await audioPlayer.seekToNext();
    } catch (e) {
      print('❌ Next hatası: $e');
    }
  }

  Future<void> previous() async {
    try {
      await audioPlayer.seekToPrevious();
    } catch (e) {
      print('❌ Previous hatası: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      print('⏩ Pozisyon değiştiriliyor: ${position.inSeconds} saniye');
      await audioPlayer.seek(position);

      // Seek sonrası state'i hemen güncelle
      emit(state.copyWith(
        position: position,
        currentPosition: position.inMilliseconds.toDouble(),
      ));
    } catch (e) {
      print('❌ Seek hatası: $e');
    }
  }

  Future<void> toggleLoopMode() async {
    try {
      final newLoopMode = !state.loopMode;
      await audioPlayer.setLoopMode(newLoopMode ? LoopMode.one : LoopMode.off);
      emit(state.copyWith(loopMode: newLoopMode));
    } catch (e) {
      print('❌ ToggleLoopMode hatası: $e');
    }
  }

  Future<void> toggleShuffle() async {
    try {
      final newShuffleMode = !state.shuffleMode;
      await audioPlayer.setShuffleModeEnabled(newShuffleMode);
      emit(state.copyWith(shuffleMode: newShuffleMode));
    } catch (e) {
      print('❌ ToggleShuffle hatası: $e');
    }
  }

  AudioStatus _getStatusFromProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AudioStatus.loading;
      case ProcessingState.ready:
        return AudioStatus.playing;
      case ProcessingState.completed:
        return AudioStatus.stopped;
      case ProcessingState.idle:
        return AudioStatus.stopped;
    }
  }
}

extension PlaylistSourceExt on PlaylistSource? {
  PlaylistSource get orDefault => this ?? PlaylistSource.allSongs;
}
