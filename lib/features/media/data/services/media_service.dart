import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:typed_data';
import '../models/media.dart';
import '../models/sort_type.dart';
import 'cache_manager.dart' as local_cache;
import 'dart:collection';

class MediaService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final List<SongModel> _allMedia = [];

  // Basit bir ValueNotifier kullanarak state yönetimi
  final ValueNotifier<List<SongModel>> mediaNotifier =
      ValueNotifier<List<SongModel>>([]);
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);

  // Artwork önbelleği için maksimum boyut
  static const int _maxCacheSize = 100;

  // LRU Cache mantığıyla çalışan önbellek
  final _artworkCache = LinkedHashMap<int, Uint8List>();

  MediaService();

  Future<bool> requestPermission() async {
    try {
      // Önce mevcut izin durumlarını kontrol et
      final audioStatus = await Permission.audio.status;
      final storageStatus = await Permission.storage.status;

      // Eğer zaten izinler verilmişse
      if (audioStatus.isGranted || storageStatus.isGranted) {
        return true;
      }

      // Android 13 ve üzeri için önce audio izni iste
      if (audioStatus.isDenied) {
        final status = await Permission.audio.request();
        if (status.isGranted) return true;
      }

      // Eğer audio izni verilmediyse storage izni iste
      if (storageStatus.isDenied) {
        final status = await Permission.storage.request();
        if (status.isGranted) return true;
      }

      return false;
    } catch (e) {
      print('İzin isteği hatası: $e');
      return false;
    }
  }

  Future<List<SongModel>> getAllSongs() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _allMedia.clear();
      _allMedia.addAll(songs);
      return songs;
    } catch (e) {
      print('Medya yükleme hatası: $e');
      return [];
    }
  }

  Future<void> loadAllMedia() async {
    loadingNotifier.value = true;
    try {
      // İzin kontrolünü sadece burada yapalım
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('Medya izinleri verilmedi');
        return;
      }

      final songs = await getAllSongs();
      mediaNotifier.value = List.from(songs);
    } catch (e) {
      print('Medya yükleme hatası: $e');
    } finally {
      loadingNotifier.value = false;
    }
  }

  // Basitleştirilmiş artwork yükleme
  Future<Uint8List?> getArtwork(int id) async {
    try {
      if (_artworkCache.containsKey(id)) {
        // Varolan artwork'ü en sona taşı
        final artwork = _artworkCache.remove(id);
        _artworkCache[id] = artwork!;
        return artwork;
      }

      final artwork = await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        quality: 25,
        size: 100,
      );

      if (artwork != null) {
        // Önbellek boyutu aşıldıysa en eski elemanı sil
        if (_artworkCache.length >= _maxCacheSize) {
          _artworkCache.remove(_artworkCache.keys.first);
        }
        _artworkCache[id] = artwork;
      }

      return artwork;
    } catch (e) {
      print('Artwork yükleme hatası: $e');
      return null;
    }
  }

  Future<List<SongModel>> filterMedia({
    String? query,
    String? artist,
    String? album,
    Duration? minDuration,
    Duration? maxDuration,
  }) async {
    // Filtreleme işlemini ana thread'de yapıyoruz
    return _allMedia.where((media) {
      if (query != null &&
          !media.title.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      if (artist != null &&
          media.artist?.toLowerCase() != artist.toLowerCase()) {
        return false;
      }
      if (album != null && media.album?.toLowerCase() != album.toLowerCase()) {
        return false;
      }
      if (minDuration != null &&
          Duration(milliseconds: media.duration ?? 0) < minDuration) {
        return false;
      }
      if (maxDuration != null &&
          Duration(milliseconds: media.duration ?? 0) > maxDuration) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<AlbumModel>> getAlbums() async {
    // Burada da tekrar izin kontrolü yapmayalım
    try {
      return await _audioQuery.queryAlbums();
    } catch (e) {
      print('Albüm yükleme hatası: $e');
      return [];
    }
  }

  Future<List<String>> getFolders() async {
    final songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    // Tüm şarkıların yollarından klasörleri çıkar
    final folders = songs
        .map((song) {
          final path = song.data;
          return path.substring(
              0, path.lastIndexOf('/')); // Son / işaretine kadar al
        })
        .toSet()
        .toList(); // Tekrar edenleri temizle

    return folders;
  }

  Future<List<SongModel>> searchMedia(String query) async {
    if (query.isEmpty) return [];

    return _allMedia.where((song) {
      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final album = (song.album ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
          artist.contains(searchQuery) ||
          album.contains(searchQuery);
    }).toList();
  }

  Future<List<AlbumModel>> searchAlbums(String query) async {
    if (query.isEmpty) return [];

    final albums = await _audioQuery.queryAlbums();
    return albums.where((album) {
      final albumName = album.album.toLowerCase();
      final artist = (album.artist ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return albumName.contains(searchQuery) || artist.contains(searchQuery);
    }).toList();
  }

  Future<List<String>> searchFolders(String query) async {
    if (query.isEmpty) return [];

    final folders = await getFolders();
    return folders.where((folder) {
      return folder.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<List<SongModel>> searchInFolder(
      String folderName, String query) async {
    return _allMedia.where((song) {
      final isInFolder = song.data.split('/').contains(folderName);
      if (!isInFolder) return false;

      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) || artist.contains(searchQuery);
    }).toList();
  }

  Future<List<SongModel>> searchInAlbum(String albumName, String query) async {
    return _allMedia.where((song) {
      final isInAlbum =
          (song.album ?? '').toLowerCase() == albumName.toLowerCase();
      if (!isInAlbum) return false;

      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) || artist.contains(searchQuery);
    }).toList();
  }

  void dispose() {
    mediaNotifier.dispose();
    loadingNotifier.dispose();
  }

  void reset() {
    _allMedia.clear();
    mediaNotifier.value = [];
    loadingNotifier.value = false;
  }
}

// Filtreleme parametreleri için yardımcı sınıf
class _FilterParams {
  final List<SongModel> list;
  final String? query;
  final String? artist;
  final String? album;
  final Duration? minDuration;
  final Duration? maxDuration;

  _FilterParams({
    required this.list,
    this.query,
    this.artist,
    this.album,
    this.minDuration,
    this.maxDuration,
  });
}

// Sıralama parametreleri için yardımcı sınıf
class _SortParams {
  final List<SongModel> list;
  final MediaSortType sortType;
  final SortOrder sortOrder;

  _SortParams(this.list, this.sortType, this.sortOrder);
}

// Filtreleme için statik metod
List<SongModel> _filterMediaList(_FilterParams params) {
  return params.list.where((media) {
    if (params.query != null &&
        !media.title.toLowerCase().contains(params.query!.toLowerCase())) {
      return false;
    }
    if (params.artist != null &&
        media.artist?.toLowerCase() != params.artist!.toLowerCase()) {
      return false;
    }
    if (params.album != null &&
        media.album?.toLowerCase() != params.album!.toLowerCase()) {
      return false;
    }
    if (params.minDuration != null &&
        Duration(milliseconds: media.duration ?? 0) < params.minDuration!) {
      return false;
    }
    if (params.maxDuration != null &&
        Duration(milliseconds: media.duration ?? 0) > params.maxDuration!) {
      return false;
    }
    return true;
  }).toList();
}
