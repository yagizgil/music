class AudioServiceImpl {
  static final AudioServiceImpl _instance = AudioServiceImpl._internal();
  factory AudioServiceImpl() => _instance;
  AudioServiceImpl._internal();

  late AudioPlayer _audioPlayer;
  late AudioHandler _audioHandler;
  final _audioPlayerCubit = AudioPlayerCubit();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    print('🎵 Audio Service başlatılıyor...');

    _audioPlayer = AudioPlayer();

    // Background service'i başlat
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(_audioPlayer, _audioPlayerCubit),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.channel.audio',
        androidNotificationChannelName: 'Müzik Oynatıcı',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: Colors.deepPurple,
      ),
    );

    _setupListeners();
    _isInitialized = true;
    print('✅ Audio Service başlatıldı');
  }

  void _setupListeners() {
    // Player durumu dinleyicisi
    _audioPlayer.playerStateStream.listen((state) {
      print(
          '🎵 Player durumu değişti: ${state.processingState}, Playing: ${state.playing}');
      _audioPlayerCubit.updatePlaybackState(state);
    });

    // Şarkı değişim dinleyicisi
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        print('📑 Şarkı index değişti: $index');
        _audioPlayerCubit.updateCurrentSongIndex(index);
      }
    });

    // Pozisyon dinleyicisi
    _audioPlayer.positionStream.listen((position) {
      _audioPlayerCubit.updatePosition(position);
    });

    // Süre dinleyicisi
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        print('⏱️ Toplam süre: ${duration.inSeconds} saniye');
        _audioPlayerCubit.updateDuration(duration);
      }
    });
  }

  Future<void> playPlaylist({
    required List<SongModel> songs,
    required int initialIndex,
  }) async {
    print('🎵 Playlist yükleniyor (${songs.length} şarkı)');

    try {
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
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: initialIndex,
      );

      // Çalmaya başla
      await _audioPlayer.play();

      // State'i güncelle
      _audioPlayerCubit.updatePlaylist(songs, initialIndex);

      print('✅ Playlist başlatıldı: ${songs[initialIndex].title}');
    } catch (e) {
      print('❌ Playlist yükleme hatası: $e');
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        print('⏸️ Duraklatılıyor');
        await _audioPlayer.pause();
      } else {
        print('▶️ Devam ediliyor');
        await _audioPlayer.play();
      }
    } catch (e) {
      print('❌ Play/Pause hatası: $e');
    }
  }

  Future<void> next() async {
    try {
      print('⏭️ Sonraki şarkıya geçiliyor');
      await _audioPlayer.seekToNext();
    } catch (e) {
      print('❌ Next hatası: $e');
    }
  }

  Future<void> previous() async {
    try {
      print('⏮️ Önceki şarkıya geçiliyor');
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      print('❌ Previous hatası: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      print('⏩ Pozisyon değiştiriliyor: ${position.inSeconds} saniye');
      await _audioPlayer.seek(position);
    } catch (e) {
      print('❌ Seek hatası: $e');
    }
  }

  AudioPlayerCubit get cubit => _audioPlayerCubit;
  AudioPlayer get player => _audioPlayer;
}
