import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart'; // VoidCallback için
import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:async'; // StreamSubscription için
import '../../data/services/media_service.dart';
import '../../data/models/sort_type.dart' show MediaSortType, SortOrder;
import '../../data/models/view_options.dart';
import 'package:flutter/material.dart';
import '../../data/models/search_filter.dart';
import '../../data/models/media.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/services/database_service.dart';
import '../../data/models/custom_album.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../data/models/song_model_extension.dart';

part 'media_state.dart';

class MediaCubit extends Cubit<MediaState> {
  final MediaService mediaService;
  final DatabaseService databaseService;
  late final VoidCallback _mediaListener;
  late final VoidCallback _loadingListener;

  MediaCubit({
    required this.mediaService,
    required this.databaseService,
  }) : super(const MediaState()) {
    _initListeners();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await loadMedia();
      await Future.wait([
        loadAlbums(),
        loadFavorites(),
        loadPlayData(),
        loadRecentlyPlayed(),
        _loadPinnedFavorites(),
        _loadPinnedAlbums(),
      ]);
    } catch (e) {
      print('Veri yükleme hatası: $e');
    }
  }

  Future<void> loadMedia() async {
    try {
      emit(state.copyWith(status: MediaStatus.loading));

      final hasPermission = await mediaService.requestPermission();
      if (!hasPermission) {
        emit(state.copyWith(
          status: MediaStatus.failure,
          error: 'Medya izinleri verilmedi. Lütfen ayarlardan izin verin.',
        ));
        return;
      }

      final results = await Future.wait([
        mediaService.getAllSongs(),
        mediaService.getAlbums(),
        mediaService.getFolders(),
      ]);

      if (results[0].isEmpty) {
        emit(state.copyWith(
          status: MediaStatus.failure,
          error: 'Medya dosyası bulunamadı.',
        ));
        return;
      }

      // Şarkıları tarihe göre sırala
      final songs = (results[0] as List<SongModel>)
        ..sort((a, b) {
          return (b.dateAdded ?? 0)
              .compareTo(a.dateAdded ?? 0); // Son eklenen en üstte
        });

      emit(state.copyWith(
        songs: songs,
        albums: results[1] as List<AlbumModel>,
        folders: results[2] as List<String>,
        tracks: songs, // Sıralanmış listeyi tracks'e de ata
        status: MediaStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MediaStatus.failure,
        error: 'Medya yüklenirken bir hata oluştu: ${e.toString()}',
      ));
    }
  }

  void _initListeners() {
    _mediaListener = () {
      if (state.status != MediaStatus.loading) {
        emit(state.copyWith(
          songs: mediaService.mediaNotifier.value,
          status: MediaStatus.success,
        ));
      }
    };

    _loadingListener = () {
      if (mediaService.loadingNotifier.value) {
        emit(state.copyWith(status: MediaStatus.loading));
      }
    };

    mediaService.mediaNotifier.addListener(_mediaListener);
    mediaService.loadingNotifier.addListener(_loadingListener);
  }

  void updateSort(MediaSortType? type, SortOrder? order) {
    if (type == null && order == null) return;

    // Mevcut şarkı listesini al
    final currentSongs = List<SongModel>.from(state.songs);

    // Sıralama kriterlerini güncelle
    final newSortType = type ?? state.sortType;
    final newSortOrder = order ?? state.sortOrder;

    // Şarkıları sırala
    currentSongs.sort((a, b) {
      int comparison = 0;
      switch (newSortType) {
        case MediaSortType.title:
          comparison = a.title.compareTo(b.title);
          break;
        case MediaSortType.artist:
          comparison = (a.artist ?? '').compareTo(b.artist ?? '');
          break;
        case MediaSortType.album:
          comparison = (a.album ?? '').compareTo(b.album ?? '');
          break;
        case MediaSortType.duration:
          comparison = (a.duration ?? 0).compareTo(b.duration ?? 0);
          break;
        case MediaSortType.dateAdded:
          comparison = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
          break;
        case MediaSortType.size:
          comparison = (a.size ?? 0).compareTo(b.size ?? 0);
          break;
      }
      return newSortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    // State'i güncelle
    emit(state.copyWith(
      songs: currentSongs,
      sortType: newSortType,
      sortOrder: newSortOrder,
    ));
  }

  void filterSongs({
    String? query,
    String? artist,
    String? album,
    Duration? minDuration,
    Duration? maxDuration,
  }) async {
    emit(state.copyWith(status: MediaStatus.loading));

    try {
      final filteredSongs = await mediaService.filterMedia(
        query: query,
        artist: artist,
        album: album,
        minDuration: minDuration,
        maxDuration: maxDuration,
      );

      emit(state.copyWith(
        songs: filteredSongs,
        status: MediaStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Filtreleme sırasında bir hata oluştu',
        status: MediaStatus.failure,
      ));
    }
  }

  @override
  Future<void> close() {
    mediaService.mediaNotifier.removeListener(_mediaListener);
    mediaService.loadingNotifier.removeListener(_loadingListener);
    _savePinnedFavorites();
    _savePinnedAlbums();
    return super.close();
  }

  void reset() {
    mediaService.reset();
    emit(const MediaState());
  }

  void updateViewOptions(ViewOptions newOptions) {
    emit(state.copyWith(viewOptions: newOptions));
  }

  List<List<SongModel>> groupSongs(List<SongModel> songs) {
    if (!state.viewOptions.enableGrouping) {
      return [songs];
    }

    final grouped = <String, List<SongModel>>{};
    String key;

    for (var song in songs) {
      switch (state.viewOptions.groupingMode) {
        case GroupingMode.alphabetical:
          key = song.title[0].toUpperCase();
          break;
        case GroupingMode.byDate:
          final date = DateTime.fromMillisecondsSinceEpoch(song.dateAdded ?? 0);
          key = '${date.year}-${date.month}';
          break;
        case GroupingMode.byArtist:
          key = song.artist ?? 'Bilinmeyen Sanatçı';
          break;
        case GroupingMode.byAlbum:
          key = song.album ?? 'Albümsüz';
          break;
        default:
          key = '';
      }
      grouped.putIfAbsent(key, () => []).add(song);
    }

    return grouped.values.toList();
  }

  Future<void> search({
    required String query,
    required Set<SearchFilter> filters,
  }) async {
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    emit(state.copyWith(status: MediaStatus.loading));

    final results = <SearchResult>[];

    try {
      if (filters.contains(SearchFilter.media)) {
        final mediaResults = await mediaService.searchMedia(query);
        results.addAll(mediaResults.map((song) => SearchResult(
              title: song.title,
              subtitle: song.artist ?? 'Bilinmeyen Sanatçı',
              icon: QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                nullArtworkWidget: const Icon(Icons.music_note),
              ),
            )));
      }

      if (filters.contains(SearchFilter.albumNames)) {
        final albumResults = await mediaService.searchAlbums(query);
        results.addAll(albumResults.map((album) => SearchResult(
              title: album.album,
              subtitle: '${album.numOfSongs} şarkı',
              icon: QueryArtworkWidget(
                id: album.id,
                type: ArtworkType.ALBUM,
                nullArtworkWidget: const Icon(Icons.album),
              ),
            )));
      }

      // Diğer filtreler için benzer işlemler...

      emit(state.copyWith(
        searchResults: results,
        status: MediaStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MediaStatus.failure,
        error: 'Arama sırasında bir hata oluştu',
      ));
    }
  }

  void toggleFavorite(SongModel song) {
    final List<SongModel> currentFavorites = List.from(state.favorites);

    if (isFavorite(song)) {
      currentFavorites.removeWhere((s) => s.id == song.id);
    } else {
      currentFavorites.add(song);
    }

    emit(state.copyWith(favorites: currentFavorites));
    _saveFavorites(currentFavorites);
  }

  bool isFavorite(SongModel song) {
    return state.favorites.any((s) => s.id == song.id);
  }

  Future<void> _saveFavorites(List<SongModel> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = favorites.map((s) => s.id.toString()).toList();
    await prefs.setStringList('favorites', favoriteIds);
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorites') ?? [];

    // Önce tüm favorileri al
    final allFavorites = state.songs
        .where((song) => favoriteIds.contains(song.id.toString()))
        .toList();

    // Pinlenmiş ve pinlenmemiş olarak ayır
    final pinned = allFavorites
        .where((song) => state.pinnedFavorites.contains(song.id))
        .toList();
    final unpinned = allFavorites
        .where((song) => !state.pinnedFavorites.contains(song.id))
        .toList();

    // Pinlenmemiş olanları sırala
    unpinned.sort((a, b) {
      int result;
      switch (state.sortType) {
        case MediaSortType.title:
          result = a.title.compareTo(b.title);
          break;
        case MediaSortType.dateAdded:
          result = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
          break;
        default:
          result = a.title.compareTo(b.title);
      }
      return state.sortOrder == SortOrder.ascending ? result : -result;
    });

    // Pinlenenler üstte, diğerleri altta olacak şekilde birleştir
    emit(state.copyWith(favorites: [...pinned, ...unpinned]));
  }

  Future<void> incrementPlayCount(SongModel song) async {
    try {
      final playCount = Map<int, int>.from(state.playCount);
      playCount[song.id] = (playCount[song.id] ?? 0) + 1;

      final recentlyPlayed = List<SongModel>.from(state.recentlyPlayed);
      recentlyPlayed.removeWhere((s) => s.id == song.id);
      recentlyPlayed.insert(0, song);
      if (recentlyPlayed.length > 50) recentlyPlayed.removeLast();

      emit(state.copyWith(
        playCount: playCount,
        recentlyPlayed: recentlyPlayed,
      ));

      await _savePlayData();
    } catch (e) {
      print('Oynatma sayısı güncellenirken hata: $e');
    }
  }

  Future<void> _savePlayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Oynatma sayılarını kaydet
      final playCountMap =
          state.playCount.map((key, value) => MapEntry(key.toString(), value));
      await prefs.setString('play_counts', jsonEncode(playCountMap));

      // Son oynatılanları kaydet
      final recentlyPlayedIds = state.recentlyPlayed.map((s) => s.id).toList();
      await prefs.setString('recently_played', jsonEncode(recentlyPlayedIds));
    } catch (e) {
      print('Oynatma verileri kaydedilirken hata: $e');
    }
  }

  Future<void> loadPlayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Oynatma sayılarını yükle
      final playCountJson = prefs.getString('play_counts');
      if (playCountJson != null) {
        final Map<String, dynamic> playCountMap = jsonDecode(playCountJson);
        final playCount = playCountMap
            .map((key, value) => MapEntry(int.parse(key), value as int));

        // Son oynatılanları yükle
        final recentlyPlayedJson = prefs.getString('recently_played');
        if (recentlyPlayedJson != null) {
          final List<dynamic> recentlyPlayedIds =
              jsonDecode(recentlyPlayedJson);
          final recentlyPlayed = state.songs
              .where((song) => recentlyPlayedIds.contains(song.id))
              .toList();

          emit(state.copyWith(
            playCount: playCount,
            recentlyPlayed: recentlyPlayed,
          ));
        }
      }
    } catch (e) {
      print('Oynatma verileri yüklenirken hata: $e');
    }
  }

  void changeSortType(MediaSortType sortType) {
    emit(state.copyWith(sortType: sortType));
    _sortFavorites();
  }

  void toggleSortOrder() {
    final newOrder = state.sortOrder == SortOrder.ascending
        ? SortOrder.descending
        : SortOrder.ascending;
    emit(state.copyWith(sortOrder: newOrder));
    _sortFavorites();
  }

  void togglePinFavorite(int songId) {
    // Önce pin durumunu güncelle
    final pinnedFavorites = Set<int>.from(state.pinnedFavorites);
    if (pinnedFavorites.contains(songId)) {
      pinnedFavorites.remove(songId);
    } else {
      pinnedFavorites.add(songId);
    }

    emit(state.copyWith(pinnedFavorites: pinnedFavorites));
    _savePinnedFavorites();
    loadFavorites(); // Favorileri yeniden yükle ve sırala
  }

  void togglePinAlbum(int albumId) {
    final pinnedAlbums = Set<int>.from(state.pinnedAlbums);
    if (pinnedAlbums.contains(albumId)) {
      pinnedAlbums.remove(albumId);
    } else {
      pinnedAlbums.add(albumId);
    }
    emit(state.copyWith(pinnedAlbums: pinnedAlbums));
    _savePinnedAlbums();
    _sortAlbums();
  }

  void _sortFavorites() {
    final favorites = List<SongModel>.from(state.favorites);

    // Önce pinlenmiş öğeleri ayır
    final pinned = favorites
        .where((song) => state.pinnedFavorites.contains(song.id))
        .toList();
    final unpinned = favorites
        .where((song) => !state.pinnedFavorites.contains(song.id))
        .toList();

    // Pinlenmemiş öğeleri sırala
    unpinned.sort((a, b) {
      int result;
      switch (state.sortType) {
        case MediaSortType.title:
          result = a.title.compareTo(b.title);
          break;
        case MediaSortType.dateAdded:
          result = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
          break;
        default:
          result = a.title.compareTo(b.title);
      }
      return state.sortOrder == SortOrder.ascending ? result : -result;
    });

    // Pinlenmiş ve pinlenmemiş öğeleri birleştir
    emit(state.copyWith(favorites: [...pinned, ...unpinned]));
  }

  Future<void> loadRecentlyPlayed() async {
    try {
      final db = await databaseService.database;
      final List<Map<String, dynamic>> recentMaps = await db.query(
        'recently_played',
        orderBy: 'playedAt DESC',
      );

      final recentSongs = <SongModel>[];
      for (var map in recentMaps) {
        final songId = map['songId'] as int;
        final song = state.songs.firstWhere(
          (s) => s.id == songId,
          orElse: () => SongModel({}), // Boş bir SongModel döndür
        );
        if (song.id != 0) {
          // Geçerli bir şarkı ise ekle
          recentSongs.add(song);
        }
      }

      emit(state.copyWith(recentlyPlayed: recentSongs));
    } catch (e) {
      emit(state.copyWith(
        error: 'Son çalınanlar yüklenirken hata oluştu',
        status: MediaStatus.failure,
      ));
    }
  }

  Future<void> addToRecentlyPlayed(SongModel song) async {
    try {
      final db = await databaseService.database;
      await db.insert(
        'recently_played',
        {
          'songId': song.id,
          'playedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm:
            sqflite.ConflictAlgorithm.replace, // sqflite import edilmeli
      );
      await loadRecentlyPlayed();
    } catch (e) {
      // Hata işleme
    }
  }

  Future<void> createAlbumWithSongs({
    required String name,
    required List<SongModel> songs,
  }) async {
    try {
      final db = await databaseService.database;

      // Kapak resmi için ilk şarkıyı dene
      String? coverPath;
      for (var song in songs) {
        final artwork = await OnAudioQuery().queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
        );

        if (artwork != null) {
          final tempFile = File(
              '${(await getApplicationDocumentsDirectory()).path}/album_temp.jpg');
          await tempFile.writeAsBytes(artwork);
          coverPath = tempFile.path;
          break;
        }
      }

      // Albümü oluştur
      final now = DateTime.now();
      final albumId = await db.insert('albums', {
        'name': name,
        'coverPath': coverPath,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // Kapak resmini kalıcı konuma taşı
      if (coverPath != null) {
        final newPath =
            '${(await getApplicationDocumentsDirectory()).path}/album_$albumId.jpg';
        await File(coverPath).copy(newPath);
        await db.update(
          'albums',
          {'coverPath': newPath},
          where: 'id = ?',
          whereArgs: [albumId],
        );
      }

      // Şarkıları albüme ekle
      final batch = db.batch();
      for (var song in songs) {
        batch.insert('album_songs', {
          'albumId': albumId,
          'songId': song.id,
        });
      }
      await batch.commit();

      // Albümleri yeniden yükle
      await loadAlbums();

      emit(state.copyWith(status: MediaStatus.success));
    } catch (e) {
      print('Albüm oluşturma hatası: $e');
      emit(state.copyWith(
        error: 'Albüm oluşturulurken bir hata oluştu: $e',
        status: MediaStatus.failure,
      ));
    }
  }

  Future<void> loadAlbums() async {
    try {
      if (state.songs.isEmpty) {
        print('⚠️ Şarkılar yüklenmeden albümler yüklenemez');
        return;
      }

      final db = await databaseService.database;
      print('📚 Albümler yükleniyor...');

      final List<Map<String, dynamic>> albumMaps = await db.query('albums');
      print('📚 ${albumMaps.length} albüm bulundu');

      final List<CustomAlbum> albums =
          albumMaps.map((map) => CustomAlbum.fromMap(map)).toList();
      final albumsWithSongs = <CustomAlbum, List<SongModel>>{};

      for (var album in albums) {
        print('🎵 ${album.name} albümü için şarkılar yükleniyor...');

        final List<Map<String, dynamic>> songIdMaps = await db.query(
          'album_songs',
          columns: ['songId'],
          where: 'albumId = ?',
          whereArgs: [album.id],
        );

        final songIds = songIdMaps.map((map) => map['songId'] as int).toList();
        print('🎵 ${songIds.length} şarkı ID\'si bulundu');

        final songs =
            state.songs.where((song) => songIds.contains(song.id)).toList();
        print('🎵 ${songs.length} şarkı eşleştirildi');

        if (songs.isNotEmpty) {
          albumsWithSongs[album] = songs;
        }
      }

      emit(state.copyWith(
        customAlbums: albumsWithSongs,
        status: MediaStatus.success,
      ));

      print('📚 Albümler başarıyla yüklendi');
    } catch (e) {
      print('❌ Albüm yükleme hatası: $e');
      emit(state.copyWith(
        error: 'Albümler yüklenirken bir hata oluştu: $e',
        status: MediaStatus.failure,
      ));
    }
  }

  Future<void> addSongsToAlbum({
    required int albumId,
    required List<SongModel> songs,
  }) async {
    try {
      final db = await databaseService.database;
      final now = DateTime.now();

      // Şarkıları albüme ekle
      final batch = db.batch();
      for (var song in songs) {
        batch.insert('album_songs', {
          'albumId': albumId,
          'songId': song.id,
          'addedAt': now.toIso8601String(),
        });
      }
      await batch.commit();

      // Albümleri yeniden yükle
      await loadAlbums();
    } catch (e) {
      emit(state.copyWith(
        error: 'Şarkılar albüme eklenirken bir hata oluştu',
        status: MediaStatus.failure,
      ));
    }
  }

  Future<void> deleteAlbumWithSongs(List<AlbumModel> albums) async {
    try {
      final db = await databaseService.database;

      for (var album in albums) {
        await db.delete(
          'albums',
          where: 'id = ?',
          whereArgs: [album.id],
        );
      }

      await loadAlbums();
    } catch (e) {
      emit(state.copyWith(
        error: 'Albümler silinirken bir hata oluştu',
        status: MediaStatus.failure,
      ));
    }
  }

  Future<void> deleteCustomAlbums(List<int> albumIds) async {
    try {
      final db = await databaseService.database;

      for (var id in albumIds) {
        await db.delete(
          'albums',
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      await loadAlbums();
    } catch (e) {
      emit(state.copyWith(
        error: 'Albümler silinirken bir hata oluştu',
        status: MediaStatus.failure,
      ));
    }
  }

  Future<void> updateAlbumCover({
    required int albumId,
    int? songId,
    String? imagePath,
  }) async {
    try {
      final db = await databaseService.database;

      String? coverPath;
      if (imagePath != null) {
        coverPath = imagePath;
      } else if (songId != null) {
        // Parçanın kapak resmini kaydet
        final artwork = await OnAudioQuery().queryArtwork(
          songId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
        );

        if (artwork != null) {
          final file = File(
              '${(await getApplicationDocumentsDirectory()).path}/album_$albumId.jpg');
          await file.writeAsBytes(artwork);
          coverPath = file.path;
        }
      }

      await db.update(
        'albums',
        {'coverPath': coverPath},
        where: 'id = ?',
        whereArgs: [albumId],
      );

      await loadAlbums();
    } catch (e) {
      emit(state.copyWith(
        error: 'Albüm kapağı güncellenirken hata oluştu',
        status: MediaStatus.failure,
      ));
    }
  }

  void changeAlbumSortType(MediaSortType sortType) {
    emit(state.copyWith(albumSortType: sortType));
    _sortAlbums();
  }

  void toggleAlbumSortOrder() {
    final newOrder = state.albumSortOrder == SortOrder.ascending
        ? SortOrder.descending
        : SortOrder.ascending;
    emit(state.copyWith(albumSortOrder: newOrder));
    _sortAlbums();
  }

  void _sortAlbums() {
    final albums = state.customAlbums.entries.toList();

    // Önce pinlenmiş öğeleri ayır
    final pinned = albums
        .where((entry) => state.pinnedAlbums.contains(entry.key.id))
        .toList();
    final unpinned = albums
        .where((entry) => !state.pinnedAlbums.contains(entry.key.id))
        .toList();

    // Sıralama fonksiyonu
    int compareFunction(MapEntry<CustomAlbum, List<SongModel>> a,
        MapEntry<CustomAlbum, List<SongModel>> b) {
      int result;
      switch (state.albumSortType) {
        case MediaSortType.title:
          result = a.key.name.compareTo(b.key.name);
          break;
        case MediaSortType.dateAdded:
          result = a.key.createdAt.compareTo(b.key.createdAt);
          break;
        case MediaSortType.size:
          result = a.value.length.compareTo(b.value.length);
          break;
        default:
          result = a.key.name.compareTo(b.key.name);
      }
      return state.albumSortOrder == SortOrder.ascending ? result : -result;
    }

    // Pinlenmemiş öğeleri sırala
    unpinned.sort(compareFunction);

    // Pinlenmiş ve pinlenmemiş öğeleri birleştir
    final sortedAlbums = Map<CustomAlbum, List<SongModel>>.fromEntries([
      ...pinned,
      ...unpinned,
    ]);

    emit(state.copyWith(customAlbums: sortedAlbums));
  }

  // SharedPreferences'a pinlenmiş albümleri kaydet
  Future<void> _savePinnedAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedIds = state.pinnedAlbums.map((id) => id.toString()).toList();
      await prefs.setStringList('pinned_albums', pinnedIds);
    } catch (e) {
      print('Pinlenmiş albümler kaydedilemedi: $e');
    }
  }

  // SharedPreferences'dan pinlenmiş albümleri yükle
  Future<void> _loadPinnedAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedIds = prefs.getStringList('pinned_albums') ?? [];
      final pinnedAlbums = pinnedIds.map((id) => int.parse(id)).toSet();
      emit(state.copyWith(pinnedAlbums: pinnedAlbums));
    } catch (e) {
      print('Pinlenmiş albümler yüklenemedi: $e');
    }
  }

  void selectFolder(String folderPath) {
    emit(state.copyWith(selectedFolder: folderPath));
  }

  int getFolderTrackCount(String folderPath) {
    return state.tracks
        .where((track) => track.path.startsWith(folderPath))
        .length;
  }

  void selectTrack(SongModel track) {
    // Seçilen parçayı işle
    // Örneğin: Oynatma listesine ekle, son oynatılanları güncelle vb.
    addToRecentlyPlayed(track);
    incrementPlayCount(track);
  }

  Future<void> _savePinnedFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedIds =
          state.pinnedFavorites.map((id) => id.toString()).toList();
      await prefs.setStringList('pinned_favorites', pinnedIds);
    } catch (e) {
      print('Pinlenmiş favoriler kaydedilemedi: $e');
    }
  }

  Future<void> _loadPinnedFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedIds = prefs.getStringList('pinned_favorites') ?? [];
      final pinnedFavorites = pinnedIds.map((id) => int.parse(id)).toSet();
      emit(state.copyWith(pinnedFavorites: pinnedFavorites));
    } catch (e) {
      print('Pinlenmiş favoriler yüklenemedi: $e');
    }
  }

  List<SongModel> getFolderTracks(String folderPath) {
    return state.tracks
        .where((track) => track.path.startsWith(folderPath))
        .toList();
  }

  static const int pageSize = 20;

  Future<void> loadMediaPage(int page) async {
    try {
      final start = page * pageSize;
      final end = start + pageSize;

      if (start >= state.songs.length) return;

      final pageItems = state.songs
          .sublist(start, end > state.songs.length ? state.songs.length : end);

      emit(state.copyWith(
        currentPage: page,
        displayedSongs: [...state.displayedSongs, ...pageItems],
      ));
    } catch (e) {
      print('Sayfa yükleme hatası: $e');
    }
  }
}
