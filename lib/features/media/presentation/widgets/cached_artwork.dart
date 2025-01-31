import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../widgets/media_list.dart';
import '../widgets/favorites_list.dart';
import '../widgets/scrollable_media_row.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../pages/most_played_page.dart';
import '../pages/recently_played_page.dart';
import 'dart:developer' as developer;
import '../../data/services/cache_manager.dart';

class CachedArtwork extends StatefulWidget {
  final int id;
  final double size;
  final double borderRadius;
  final Widget? nullArtworkWidget;

  const CachedArtwork({
    super.key,
    required this.id,
    required this.size,
    this.borderRadius = 8,
    this.nullArtworkWidget,
  });

  @override
  State<CachedArtwork> createState() => CachedArtworkState();
}

class CachedArtworkState extends State<CachedArtwork> {
  static final artworkCache = <int, Widget>{};
  static final onAudioQuery = OnAudioQuery();
  late Future<Widget> _artworkFuture;

  @override
  void initState() {
    super.initState();
    _artworkFuture = _loadArtwork();
  }

  String _getLocation() {
    try {
      if (!mounted) return 'Widget artık aktif değil';

      final context = this.context;
      final ancestors = <String>[];

      context.visitAncestorElements((element) {
        if (element.widget is MediaList) ancestors.add('MediaList');
        if (element.widget is FavoritesList) ancestors.add('FavoritesList');
        if (element.widget is ScrollableMediaRow)
          ancestors.add('ScrollableMediaRow');
        if (element.widget is PlayerPage) ancestors.add('PlayerPage');
        if (element.widget is MostPlayedPage) ancestors.add('MostPlayedPage');
        if (element.widget is RecentlyPlayedPage)
          ancestors.add('RecentlyPlayedPage');
        return true;
      });

      if (ancestors.isEmpty) return 'Widget ağacında bulunamadı';
      return ancestors.join(' -> ');
    } catch (e) {
      return 'Hata: $e';
    }
  }

  Future<Widget> _loadArtwork() async {
    final location = _getLocation();

    if (artworkCache.containsKey(widget.id)) {
      debugPrint('🎵 Cache HIT [${widget.id}] - $location');
      return artworkCache[widget.id]!;
    }

    debugPrint('🔄 Cache MISS [${widget.id}] - $location');

    try {
      final artworkFile = await onAudioQuery.queryArtwork(
        widget.id,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
        quality: 75,
      );

      if (artworkFile != null) {
        final artwork = Image.memory(
          artworkFile,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          cacheWidth: 200,
          cacheHeight: 200,
        );
        artworkCache[widget.id] = artwork;
        debugPrint('✅ Artwork yüklendi [${widget.id}] - $location');
        return artwork;
      }
    } catch (e) {
      debugPrint('❌ Artwork hatası [${widget.id}] - $location - $e');
    }

    final fallback = Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
    artworkCache[widget.id] = fallback;
    return fallback;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<Widget>(
          future: _artworkFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            }
            return widget.nullArtworkWidget ?? _buildPlaceholder();
          },
        ),
      ),
    );
  }
}
