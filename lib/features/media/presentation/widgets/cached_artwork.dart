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

class CachedArtwork extends StatelessWidget {
  final int id;
  final double size;
  final double borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CachedArtwork({
    super.key,
    required this.id,
    required this.size,
    this.borderRadius = 8,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: QueryArtworkWidget(
          id: id,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          format: ArtworkFormat.JPEG,
          size: memCacheWidth ?? size.toInt(),
          quality: 80,
          artworkQuality: FilterQuality.low,
          artworkBorder: BorderRadius.zero,
          nullArtworkWidget: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.music_note,
              size: size * 0.5,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
