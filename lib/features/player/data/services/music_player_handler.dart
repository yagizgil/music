import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../presentation/cubit/audio_player_cubit.dart';

class MusicPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final AudioPlayerCubit _playerCubit;

  MusicPlayerHandler(this._player, this._playerCubit) {
    // _player.playbackEventStream.listen(_broadcastState);
    // _player.durationStream.listen((duration) {
    //   if (duration != null) {
    //     mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    //   }
    // });
  }

  // @override
  // Future<void> skipToPrevious() async {
  //   await _playerCubit.previous();
  //   playbackState.add(playbackState.value.copyWith(
  //     playing: true,
  //     controls: [
  //       MediaControl.skipToPrevious,
  //       MediaControl.pause,
  //       MediaControl.skipToNext,
  //     ],
  //   ));
  // }

  // @override
  // Future<void> skipToNext() async {
  //   await _playerCubit.next();
  //   playbackState.add(playbackState.value.copyWith(
  //     playing: true,
  //     controls: [
  //       MediaControl.skipToPrevious,
  //       MediaControl.pause,
  //       MediaControl.skipToNext,
  //     ],
  //   ));
  // }

  // @override
  // Future<void> play() async {
  //   _player.play();
  //   print('\n\n\n\n\n\n🎵 Play\n\n\n\n\n\n');
  //   playbackState.add(playbackState.value.copyWith(
  //     playing: true,
  //     controls: [
  //       MediaControl.skipToPrevious,
  //       MediaControl.pause,
  //       MediaControl.skipToNext,
  //     ],
  //   ));
  // }

  // @override
  // Future<void> pause() async {
  //   _player.pause();
  //   print('\n\n\n\n\n\n🎵 Pause\n\n\n\n\n\n');
  //   playbackState.add(playbackState.value.copyWith(
  //     playing: false,
  //     controls: [
  //       MediaControl.skipToPrevious,
  //       MediaControl.play,
  //       MediaControl.skipToNext,
  //     ],
  //   ));
  // }

  // // @override
  // // Future<void> stop() => _player.stop();
  // @override
  // Future<void> stop() async {
  //   print('\n\n\n\n\n\n🎵 stopp\n\n\n\n\n\n');
  //   await _player.stop();
  //   await _playerCubit.stop();
  // }

  // @override
  // Future<void> seek(Duration position) => _player.seek(position);

  void _broadcastState(PlaybackEvent event) {
    print('\n\n\n\n\n\n🎵 broadcastState\n\n\n\n\n\n');
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  // @override
  // Future<void> updateMediaItem(MediaItem item) async {
  //   mediaItem.value = item;
  // }

  // @override
  // Future<void> playMediaItem(MediaItem mediaItem) async {
  //   try {
  //     await _player.setUrl(mediaItem.id);
  //     this.mediaItem.value = mediaItem;
  //     await play();
  //   } catch (e) {
  //     print('Error playing media item: $e');
  //   }
  // }

  // void updatePlaybackState({
  //   required List<MediaControl> controls,
  //   required Set<MediaAction> systemActions,
  //   required List<int> androidCompactActionIndices,
  //   required bool playing,
  //   required AudioProcessingState processingState,
  // }) {
  //   playbackState.add(PlaybackState(
  //     controls: controls,
  //     systemActions: systemActions,
  //     androidCompactActionIndices: androidCompactActionIndices,
  //     playing: playing,
  //     processingState: processingState,
  //     updatePosition: _player.position,
  //     bufferedPosition: _player.bufferedPosition,
  //     speed: _player.speed,
  //   ));
  // }

  // void _listenToPlaybackState() {
  //   _player.positionStream.listen((position) {
  //     playbackState.add(playbackState.value.copyWith(
  //       updatePosition: position,
  //     ));
  //   });

  //   _player.durationStream.listen((duration) {
  //     mediaItem.add(mediaItem.value?.copyWith(duration: duration));
  //   });
  // }

  Future<void> customPlaybackState({
    required bool playing,
    required Duration position,
    required Duration updatePosition,
    required Duration bufferedPosition,
    required double speed,
    required List<MediaControl> controls,
  }) async {
    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: updatePosition,
        bufferedPosition: bufferedPosition,
        speed: speed,
      ),
    );
  }
}
