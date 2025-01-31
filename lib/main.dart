import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:music_player/core/theme/app_theme.dart';
import 'package:music_player/core/theme/theme_cubit.dart';
import 'package:music_player/features/home/presentation/pages/home_page.dart';
import 'package:music_player/features/media/data/services/media_service.dart';
import 'package:music_player/features/media/presentation/cubit/media_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player/features/settings/data/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:music_player/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:music_player/features/player/presentation/pages/player_page.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_player/features/player/data/services/music_player_handler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player/features/media/data/services/database_service.dart';
import 'package:music_player/features/media/presentation/pages/folder_detail_page.dart';
import 'package:just_audio/just_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_player.channel.audio',
    androidNotificationChannelName: 'Müzik Oynatıcı',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: true, // Duraklatıldığında bildirimi küçült
    fastForwardInterval: const Duration(seconds: 10),
    rewindInterval: const Duration(seconds: 10),
    preloadArtwork: true, // Artwork'ü önceden yükle
  );

  final prefs = await SharedPreferences.getInstance();
  final mediaService = MediaService();
  final databaseService = DatabaseService();

  await mediaService.requestPermission();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<MediaService>.value(value: mediaService),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit(prefs: prefs)),
        BlocProvider<MediaCubit>(
          create: (context) => MediaCubit(
            mediaService: mediaService,
            databaseService: databaseService,
          ),
        ),
        BlocProvider(
          create: (context) => AudioPlayerCubit(
            audioPlayer: AudioPlayer(),
            mediaCubit: context.read<MediaCubit>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Music App',
          theme: AppTheme.lightTheme(themeState.primaryColor),
          darkTheme: AppTheme.darkTheme(themeState.primaryColor),
          themeMode: themeState.themeMode,
          home: const SafeArea(
            child: HomePage(),
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/player':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<AudioPlayerCubit>(),
                    child: PlayerPage(
                      playlist: args['playlist'] ?? [],
                      playlistName: args['playlistName'] ?? 'Şimdi Çalıyor',
                    ),
                  ),
                );
              case '/folder-detail':
                return MaterialPageRoute(
                  builder: (context) => FolderDetailPage(
                    folderPath: settings.arguments as String,
                  ),
                );
              default:
                return null;
            }
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
