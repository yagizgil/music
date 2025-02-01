import 'package:flutter/material.dart';
import '../../domain/enums/player_style.dart';
import 'base_player_style.dart';
import 'classic_player_style.dart';
import 'modern_player_style.dart';
import 'minimal_player_style.dart';
import 'gradient_player_style.dart';
import 'original_player_style.dart';

class PlayerStyleFactory {
  static BasePlayerStyle create({
    required PlayerStyle style,
    required state,
    required playlist,
    required playlistName,
    required onClose,
    required colorScheme,
  }) {
    switch (style) {
      case PlayerStyle.original:
        return OriginalPlayerStyle(
          state: state,
          playlist: playlist,
          playlistName: playlistName,
          onClose: onClose,
          colorScheme: colorScheme,
        );
      case PlayerStyle.classic:
        return ClassicPlayerStyle(
          state: state,
          playlist: playlist,
          playlistName: playlistName,
          onClose: onClose,
          colorScheme: colorScheme,
        );
      case PlayerStyle.modern:
        return ModernPlayerStyle(
          state: state,
          playlist: playlist,
          playlistName: playlistName,
          onClose: onClose,
          colorScheme: colorScheme,
        );
      case PlayerStyle.minimal:
        return MinimalPlayerStyle(
          state: state,
          playlist: playlist,
          playlistName: playlistName,
          onClose: onClose,
          colorScheme: colorScheme,
        );
      case PlayerStyle.gradient:
        return GradientPlayerStyle(
          state: state,
          playlist: playlist,
          playlistName: playlistName,
          onClose: onClose,
          colorScheme: colorScheme,
        );
    }
  }
}
