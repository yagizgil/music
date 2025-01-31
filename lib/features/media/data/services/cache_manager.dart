import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data'; // Uint8List için bu import gerekli
import '../models/media.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MediaCacheManager {
  static final MediaCacheManager instance = MediaCacheManager._();
  MediaCacheManager._();

  Future<String> get _cacheDir async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory(path.join(dir.path, 'media_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create();
    }
    return cacheDir.path;
  }

  Future<Media?> getCachedMedia(SongModel song) async {
    try {
      final file = File(path.join(await _cacheDir, _getFileName(song.data)));
      if (await file.exists()) {
        return Media(song: song);
      }
    } catch (e) {
      print('Cache okuma hatası: $e');
    }
    return null;
  }

  Future<void> cacheSong(SongModel song) async {
    try {
      final sourceFile = File(song.data);
      if (await sourceFile.exists()) {
        final cacheFile =
            File(path.join(await _cacheDir, _getFileName(song.data)));
        await cacheFile.writeAsBytes(await sourceFile.readAsBytes());
      }
    } catch (e) {
      print('Cache yazma hatası: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final dir = Directory(await _cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print('Cache temizleme hatası: $e');
    }
  }

  String _getFileName(String filePath) {
    return path.basename(filePath);
  }
}

class ArtworkCacheManager {
  static final Map<int, Uint8List?> _artworkCache = {};

  static Future<Uint8List?> getArtwork(int songId) async {
    // Önbellekte varsa direkt döndür
    if (_artworkCache.containsKey(songId)) {
      return _artworkCache[songId];
    }

    try {
      final artwork = await OnAudioQuery().queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: 200,
        quality: 75,
        format: ArtworkFormat.JPEG,
      );

      // Önbelleğe kaydet
      _artworkCache[songId] = artwork;
      return artwork;
    } catch (e) {
      print('Artwork yükleme hatası: $e');
      return null;
    }
  }

  static void clearCache() {
    _artworkCache.clear();
  }
}
