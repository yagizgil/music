import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:top_modal_sheet/top_modal_sheet.dart';
import '../../domain/enums/player_style.dart';
import '../../../settings/data/providers/settings_provider.dart';

class StylePopupMenu extends StatelessWidget {
  const StylePopupMenu({
    super.key,
    this.color = Colors.white,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.style_outlined, color: color),
      tooltip: 'Stil Değiştir',
      onPressed: () async {
        await showTopModalSheet<void>(
          context,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Stil Seç',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...PlayerStyle.values.map(
                  (style) => _buildStyleItem(context, style),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyleItem(BuildContext context, PlayerStyle style) {
    final currentStyle = context.read<SettingsProvider>().playerStyle;
    final isSelected = currentStyle == style;

    return InkWell(
      onTap: () {
        context.read<SettingsProvider>().setPlayerStyle(style);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                switch (style) {
                  PlayerStyle.original => Icons.music_note,
                  PlayerStyle.classic => Icons.album,
                  PlayerStyle.modern => Icons.graphic_eq,
                  PlayerStyle.minimal => Icons.minimize,
                  PlayerStyle.gradient => Icons.gradient,
                },
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _getStyleDescription(style),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _getStyleDescription(PlayerStyle style) {
    switch (style) {
      case PlayerStyle.original:
        return 'Klasik tasarımın modern yorumu';
      case PlayerStyle.classic:
        return 'Geleneksel müzik çalar deneyimi';
      case PlayerStyle.modern:
        return 'Şık ve modern tasarım';
      case PlayerStyle.minimal:
        return 'Sade ve işlevsel arayüz';
      case PlayerStyle.gradient:
        return 'Renkli ve canlı gradyan tasarım';
    }
  }
}
