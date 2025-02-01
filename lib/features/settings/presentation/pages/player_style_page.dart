import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../player/domain/enums/player_style.dart';
import '../../data/providers/settings_provider.dart';

class PlayerStylePage extends StatefulWidget {
  const PlayerStylePage({super.key});

  @override
  State<PlayerStylePage> createState() => _PlayerStylePageState();
}

class _PlayerStylePageState extends State<PlayerStylePage> {
  final PageController _pageController = PageController();
  int _currentStyleIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStyleIndex = PlayerStyle.values
        .indexOf(context.read<SettingsProvider>().playerStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Üst kısım - Stil Önizleme
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStyleIndex = index);
              },
              itemCount: PlayerStyle.values.length,
              itemBuilder: (context, index) {
                final style = PlayerStyle.values[index];
                return _buildStylePreview(style, context);
              },
            ),
          ),
          // Alt kısım - Stil Bilgileri ve Seçim
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stil İndikatörü
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      PlayerStyle.values.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentStyleIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Stil Başlığı ve Açıklaması
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        PlayerStyle.values[_currentStyleIndex].displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStyleDescription(
                            PlayerStyle.values[_currentStyleIndex]),
                        textAlign: TextAlign.center,
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
                // Seçim Butonu
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: FilledButton(
                    onPressed: () {
                      context.read<SettingsProvider>().setPlayerStyle(
                            PlayerStyle.values[_currentStyleIndex],
                          );
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Bu Stili Seç',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildStylePreview(PlayerStyle style, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (style) {
      case PlayerStyle.original:
        return _buildOriginalPreview(colorScheme);
      case PlayerStyle.classic:
        return _buildClassicPreview(colorScheme);
      case PlayerStyle.modern:
        return _buildModernPreview(colorScheme);
      case PlayerStyle.minimal:
        return _buildMinimalPreview(colorScheme);
      case PlayerStyle.gradient:
        return _buildGradientPreview(colorScheme);
    }
  }

  Widget _buildOriginalPreview(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.8),
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Şimdi Çalıyor',
                  style: TextStyle(color: Colors.white)),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Örnek Şarkı İsmi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Örnek Sanatçı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: colorScheme.secondary,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: colorScheme.secondary,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: 0.7,
                            onChanged: (_) {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('2:10',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7))),
                              Text('3:45',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.shuffle_rounded,
                          color: Colors.white.withOpacity(0.7), size: 24),
                      const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 36),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pause_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 36),
                      Icon(Icons.repeat_rounded,
                          color: Colors.white.withOpacity(0.7), size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicPreview(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.background,
      child: Column(
        children: [
          AppBar(
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Şimdi Çalıyor'),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    const Text(
                      'Örnek Şarkı İsmi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Örnek Sanatçı',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor:
                              colorScheme.primary.withOpacity(0.3),
                          thumbColor: colorScheme.primary,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4),
                        ),
                        child: Slider(
                          value: 0.7,
                          onChanged: (_) {},
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('2:10',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.7))),
                            Text('3:45',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.shuffle_rounded,
                        color: colorScheme.primary.withOpacity(0.7), size: 24),
                    const Icon(Icons.skip_previous_rounded, size: 32),
                    FloatingActionButton(
                      onPressed: () {},
                      child: const Icon(Icons.pause_rounded),
                    ),
                    const Icon(Icons.skip_next_rounded, size: 32),
                    Icon(Icons.repeat_rounded,
                        color: colorScheme.primary.withOpacity(0.7), size: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPreview(ColorScheme colorScheme) {
    final size = MediaQuery.of(context).size;
    final artworkSize = size.width * 0.6;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.8),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Column(
                children: [
                  Text(
                    'ÇALIYOR',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const Text('Çalma Listesi', style: TextStyle(fontSize: 16)),
                ],
              ),
              centerTitle: true,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: artworkSize,
                    height: artworkSize,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Örnek Şarkı İsmi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Örnek Sanatçı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Modern stil için özel slider tasarımı
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 0.7,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('2:10',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7))),
                              Text('3:45',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.shuffle_rounded,
                          color: colorScheme.primary.withOpacity(0.7),
                          size: 28),
                      const Icon(Icons.skip_previous_rounded, size: 40),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.pause_rounded,
                            color: Colors.white, size: 38),
                      ),
                      const Icon(Icons.skip_next_rounded, size: 40),
                      Icon(Icons.repeat_rounded,
                          color: colorScheme.primary.withOpacity(0.7),
                          size: 28),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalPreview(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Örnek Şarkı İsmi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Örnek Sanatçı',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                  thumbColor: colorScheme.primary,
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 4),
                ),
                child: Slider(
                  value: 0.7,
                  onChanged: (_) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.shuffle_rounded,
                        color: colorScheme.primary.withOpacity(0.7), size: 24),
                    const Icon(Icons.skip_previous_rounded, size: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                    const Icon(Icons.skip_next_rounded, size: 32),
                    Icon(Icons.repeat_rounded,
                        color: colorScheme.primary.withOpacity(0.7), size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientPreview(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
            colorScheme.tertiary,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Şimdi Çalıyor',
                  style: TextStyle(color: Colors.white)),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Örnek Şarkı İsmi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Örnek Sanatçı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: 0.7,
                            onChanged: (_) {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('2:10',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7))),
                              Text('3:45',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.shuffle_rounded,
                          color: Colors.white, size: 24),
                      const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 42),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.pause_rounded,
                            color: colorScheme.primary, size: 38),
                      ),
                      const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 42),
                      Icon(Icons.repeat_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
