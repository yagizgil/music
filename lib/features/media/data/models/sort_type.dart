import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum SortOrder {
  ascending,
  descending,
}

enum MediaSortType {
  title,
  artist,
  album,
  dateAdded,
  duration,
  size,
}

extension SortOrderExtension on SortOrder {
  OrderType get orderType {
    switch (this) {
      case SortOrder.ascending:
        return OrderType.ASC_OR_SMALLER;
      case SortOrder.descending:
        return OrderType.DESC_OR_GREATER;
    }
  }
}

extension MediaSortTypeExtension on MediaSortType {
  SongSortType get songSortType {
    switch (this) {
      case MediaSortType.title:
        return SongSortType.TITLE;
      case MediaSortType.artist:
        return SongSortType.ARTIST;
      case MediaSortType.album:
        return SongSortType.ALBUM;
      case MediaSortType.dateAdded:
        return SongSortType.DATE_ADDED;
      case MediaSortType.duration:
        return SongSortType.DURATION;
      case MediaSortType.size:
        return SongSortType.DATE_ADDED;
    }
  }
}
