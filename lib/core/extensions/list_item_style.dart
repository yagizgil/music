import 'package:flutter/material.dart';

extension ListItemStyle on Widget {
  static const listItemMargin =
      EdgeInsets.symmetric(horizontal: 8, vertical: 2);
  static const listItemPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  static const double borderRadius = 12.0;
  static const double artworkBorderRadius = 8.0;
  static const double artworkSize = 48.0;

  Widget withListItemStyle({
    required BuildContext context,
    required bool isPlaying,
  }) {
    return Container(
      margin: listItemMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color:
            isPlaying ? Theme.of(context).colorScheme.primaryContainer : null,
      ),
      child: this,
    );
  }
}

extension ListItemStyleExtension on ListTile {
  static const double listItemPadding = 8.0;
  static const double artworkSize = 50.0;
  static const double artworkBorderRadius = 8.0;

  Widget withListItemStyle({
    required BuildContext context,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: isPlaying
            ? Theme.of(context).colorScheme.primaryContainer
            : isSelected
                ? Theme.of(context).colorScheme.surfaceVariant
                : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: this,
    );
  }
}
