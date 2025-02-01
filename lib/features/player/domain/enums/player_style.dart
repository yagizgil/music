enum PlayerStyle {
  original,
  classic,
  modern,
  minimal,
  gradient;

  String get displayName {
    switch (this) {
      case PlayerStyle.original:
        return 'Orijinal';
      case PlayerStyle.classic:
        return 'Klasik';
      case PlayerStyle.modern:
        return 'Modern';
      case PlayerStyle.minimal:
        return 'Minimal';
      case PlayerStyle.gradient:
        return 'Gradyan';
    }
  }
}
