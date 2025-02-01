import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_design.dart';
import '../../../../features/player/domain/enums/player_style.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _maxCacheSizeKey = 'maxCacheSize';
  static const String _playerDesignKey = 'playerDesign';
  static const String _playerStyleKey = 'playerStyle';
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  int _maxCacheSize = 100;
  int get maxCacheSize => _maxCacheSize;

  PlayerDesign _playerDesign = PlayerDesign.normal;

  PlayerDesign get playerDesign => _playerDesign;

  PlayerStyle _playerStyle = PlayerStyle.modern;
  PlayerStyle get playerStyle => _playerStyle;

  Future<void> _loadSettings() async {
    _maxCacheSize = _prefs.getInt(_maxCacheSizeKey) ?? 100;
    _playerDesign = PlayerDesign.values[_prefs.getInt(_playerDesignKey) ?? 0];
    _playerStyle = PlayerStyle
        .values[_prefs.getInt(_playerStyleKey) ?? PlayerStyle.modern.index];
    notifyListeners();
  }

  Future<void> setMaxCacheSize(int size) async {
    _maxCacheSize = size;
    await _prefs.setInt(_maxCacheSizeKey, size);
    notifyListeners();
  }

  Future<void> setPlayerDesign(PlayerDesign design) async {
    _playerDesign = design;
    await _prefs.setInt(_playerDesignKey, design.index);
    notifyListeners();
  }

  Future<void> setPlayerStyle(PlayerStyle style) async {
    _playerStyle = style;
    await _prefs.setInt(_playerStyleKey, style.index);
    notifyListeners();
  }
}
