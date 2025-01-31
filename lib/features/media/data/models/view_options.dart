import 'package:flutter/material.dart';

enum ViewMode {
  list,
  grid,
}

enum GroupingMode {
  alphabetical,
  byDate,
  byArtist,
  byAlbum,
}

class ViewOptions {
  final ViewMode viewMode;
  final bool enableGrouping;
  final GroupingMode groupingMode;

  const ViewOptions({
    this.viewMode = ViewMode.list,
    this.enableGrouping = false,
    this.groupingMode = GroupingMode.alphabetical,
  });

  ViewOptions copyWith({
    ViewMode? viewMode,
    bool? enableGrouping,
    GroupingMode? groupingMode,
  }) {
    return ViewOptions(
      viewMode: viewMode ?? this.viewMode,
      enableGrouping: enableGrouping ?? this.enableGrouping,
      groupingMode: groupingMode ?? this.groupingMode,
    );
  }
}
