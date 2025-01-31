import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtworkCacheService {
  static final Map<int, Uint8List> _cache = {};
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static Future<Uint8List?> getArtwork(int id) async {
    if (_cache.containsKey(id)) {
      return _cache[id];
    }

    try {
      final artwork = await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        size: 1000,
        quality: 100,
        format: ArtworkFormat.JPEG,
      );

      if (artwork != null) {
        _cache[id] = artwork;
      }

      return artwork;
    } catch (e) {
      print('Artwork yükleme hatası: $e');
      return null;
    }
  }

  static void clearCache() {
    _cache.clear();
  }
}
