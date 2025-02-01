import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final currentStyle = context.watch<SettingsProvider>().playerStyle;

    return PopupMenuButton<PlayerStyle>(
      icon: Icon(Icons.style_outlined, color: color),
      tooltip: 'Stil Değiştir',
      onSelected: (style) {
        context.read<SettingsProvider>().setPlayerStyle(style);
      },
      itemBuilder: (context) => PlayerStyle.values
          .map(
            (style) => PopupMenuItem(
              value: style,
              child: Row(
                children: [
                  Icon(
                    currentStyle == style
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(style.displayName),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
