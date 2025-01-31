import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/core/theme/theme_cubit.dart';
import 'package:music_player/features/settings/data/providers/settings_provider.dart';
import '../../../media/data/services/cache_manager.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          _buildThemeSection(context),
          _buildColorSection(context),
          ListTile(
            title: Text('Önbellek Boyutu'),
            subtitle: Text('Medya önbelleği için maksimum boyut'),
            trailing: DropdownButton<int>(
              value: context.watch<SettingsProvider>().maxCacheSize,
              items: [
                DropdownMenuItem(value: 100, child: Text('100 MB')),
                DropdownMenuItem(value: 200, child: Text('200 MB')),
                DropdownMenuItem(value: 500, child: Text('500 MB')),
              ],
              onChanged: (value) {
                context.read<SettingsProvider>().setMaxCacheSize(value ?? 100);
              },
            ),
          ),
          ListTile(
            title: const Text('Önbelleği Temizle'),
            subtitle: const Text('Tüm önbelleğe alınmış medyaları temizle'),
            onTap: () async {
              try {
                await MediaCacheManager.instance.clearCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Önbellek temizlendi')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Önbellek temizlenirken hata oluştu')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return ListTile(
          leading: Icon(
            state.isDark ? Icons.dark_mode : Icons.light_mode,
          ),
          title: Text(state.isDark ? 'Karanlık Tema' : 'Aydınlık Tema'),
          trailing: Switch(
            value: state.isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
          ),
        );
      },
    );
  }

  Widget _buildColorSection(BuildContext context) {
    final colors = [
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tema Rengi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              return BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, state) {
                  return GestureDetector(
                    onTap: () {
                      context.read<ThemeCubit>().updatePrimaryColor(color);
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: state.primaryColor == color
                            ? Border.all(
                                color:
                                    state.isDark ? Colors.white : Colors.black,
                                width: 2,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
