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
  final AudioPlayer player;
  final MediaCubit mediaCubit;

  AudioPlayer get audioPlayer => player;

  AudioPlayerCubit({
    required this.player,
    required this.mediaCubit,
  }) : super(const AudioPlayerState()) {
    _setupListeners();
  }

  void _setupListeners() {
    // Player durumu dinleyicisi
    player.playerStateStream.listen((playerState) {
      emit(state.copyWith(
        isPlaying: playerState.playing,
        status: _getStatusFromProcessingState(playerState.processingState),
      ));
    });

    // Şarkı değişim ve süre bilgilerini birleştirip dinle
    Rx.combineLatest3<Duration?, Duration?, int?,
        ({Duration? duration, Duration? position, int? index})>(
      player.durationStream,
      player.positionStream,
      player.currentIndexStream,
      (duration, position, index) => (
        duration: duration,
        position: position,
        index: index,
      ),
    ).listen((data) {
      if (data.index != null &&
          data.index! >= 0 &&
          data.index! < state.currentPlaylist.length) {
        emit(state.copyWith(
          currentSong: state.currentPlaylist[data.index!],
          currentIndex: data.index,
          duration: data.duration ?? Duration.zero,
          position: data.position ?? Duration.zero,
          currentPosition: data.position?.inMilliseconds.toDouble() ?? 0,
        ));
      }
    });

    // Shuffle modu dinleyicisi
    player.shuffleModeEnabledStream.listen((enabled) {
      emit(state.copyWith(shuffleMode: enabled));
    });

    // Loop modu dinleyicisi
    player.loopModeStream.listen((loopMode) {
      emit(state.copyWith(
        loopMode: loopMode,
      ));
    });
  }

  Future<void> play(
    SongModel song, {
    required List<SongModel> playlist,
    required PlaylistSource source,
  }) async {
    try {
      // Aynı şarkıyı çalmaya çalışıyorsak sadece play/pause yap
      if (state.currentSong?.id == song.id) {
        if (player.playing) {
          await player.pause();
        } else {
          await player.play();
        }
        return;
      }

      // Önce mevcut çalmayı durdur
      await player.stop();

      // Yeni playlist için AudioSource oluştur
      final audioSource = ConcatenatingAudioSource(
        children: playlist.map((song) {
          return AudioSource.uri(
            Uri.parse(song.data),
            tag: MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist ?? 'Bilinmeyen Sanatçı',
              duration: Duration(milliseconds: song.duration ?? 0),
              // Android MediaStore URI kullan
              artUri: Uri.parse(
                  'content://media/external/audio/media/${song.id}/albumart'),
              // Yedek olarak dosya yolunu da ekle
              extras: {
                'artworkPath': song.data,
                'artworkId': song.id.toString(),
              },
            ),
          );
        }).toList(),
      );

      final initialIndex = playlist.indexOf(song);

      // State'i güncelle
      emit(state.copyWith(
        currentSong: song,
        currentPlaylist: playlist,
        currentIndex: initialIndex,
        playlistSource: source,
        status: AudioStatus.loading,
      ));

      // Yeni playlist'i ayarla ve çal
      await player.setAudioSource(audioSource, initialIndex: initialIndex);
      await player.setLoopMode(LoopMode.all);
      await player.play();
    } catch (e) {
      print('Play error: $e');
      emit(state.copyWith(status: AudioStatus.error));
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      print('Toggle play/pause error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await player.seek(position);
      emit(state.copyWith(
        position: position,
        currentPosition: position.inMilliseconds.toDouble(),
      ));
    } catch (e) {
      print('Seek error: $e');
    }
  }

  Future<void> next() async {
    try {
      await player.seekToNext();
    } catch (e) {
      print('Next error: $e');
    }
  }

  Future<void> previous() async {
    try {
      await player.seekToPrevious();
    } catch (e) {
      print('Previous error: $e');
    }
  }

  Future<void> toggleShuffle() async {
    try {
      final newShuffleMode = !state.shuffleMode;
      await player.setShuffleModeEnabled(newShuffleMode);
      emit(state.copyWith(shuffleMode: newShuffleMode));
    } catch (e) {
      print('Toggle shuffle error: $e');
    }
  }

  void toggleLoopMode() {
    final nextMode = switch (state.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };

    player.setLoopMode(nextMode);
    emit(state.copyWith(loopMode: nextMode));
  }

  Future<void> playPlaylist(
    List<SongModel> playlist, {
    int initialIndex = 0,
    required PlaylistSource source,
  }) async {
    if (playlist.isEmpty) return;
    await play(
      playlist[initialIndex],
      playlist: playlist,
      source: source,
    );
  }

  AudioStatus _getStatusFromProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AudioStatus.loading;
      case ProcessingState.ready:
        return AudioStatus.playing;
      case ProcessingState.completed:
      case ProcessingState.idle:
        return AudioStatus.stopped;
    }
  }

  @override
  Future<void> close() async {
    try {
      // Önce stream'leri durdur
      await player.stop();
      // Bekle ve sonra dispose et
      await Future.delayed(const Duration(milliseconds: 100));
      await player.dispose();
    } catch (e) {
      print('Close error: $e');
    }
    return super.close();
  }
}

extension PlaylistSourceExt on PlaylistSource? {
  PlaylistSource get orDefault => this ?? PlaylistSource.allSongs;
}
