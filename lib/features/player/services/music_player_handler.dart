class MusicPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final AudioPlayerCubit _cubit;

  MusicPlayerHandler(this._player, this._cubit) {
    _init();
  }

  void _init() {
    // Player durumunu dinle
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        playing: state.playing,
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
      ));
    });

    // Şarkı değişimlerini dinle
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState?.currentSource == null) return;
      final mediaItem = sequenceState!.currentSource!.tag as MediaItem;
      mediaItem.add(mediaItem);
    });
  }

  @override
  Future<void> play() async {
    await _cubit.resume();
  }

  @override
  Future<void> pause() async {
    await _cubit.pause();
  }

  @override
  Future<void> skipToNext() async {
    await _cubit.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _cubit.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    await _cubit.seek(position);
  }

  @override
  Future<void> stop() async {
    await _cubit.stop();
  }
}
