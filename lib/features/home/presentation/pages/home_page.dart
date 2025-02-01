import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:music_player/features/home/presentation/widgets/custom_tab_bar.dart';
import 'package:music_player/features/home/presentation/widgets/mini_player.dart';
import 'package:music_player/features/settings/presentation/pages/settings_page.dart';
import 'package:music_player/features/media/presentation/widgets/media_list.dart';
import 'package:music_player/features/media/presentation/widgets/album_list.dart';
import 'package:music_player/features/media/presentation/widgets/folder_list.dart';
import 'package:music_player/features/media/presentation/cubit/media_cubit.dart';
import 'package:music_player/features/media/presentation/widgets/recently_played_list.dart';
import 'package:music_player/features/media/presentation/widgets/most_played_list.dart';
import 'package:music_player/features/media/presentation/widgets/favorites_list.dart';
import 'package:music_player/features/media/presentation/pages/search_page.dart';
import 'package:music_player/features/media/presentation/pages/favorites_page.dart';
import 'package:music_player/features/media/presentation/pages/recently_played_page.dart';
import 'package:music_player/features/media/presentation/pages/most_played_page.dart';
import 'package:music_player/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:flutter/rendering.dart';
import 'package:music_player/features/player/presentation/pages/player_page.dart';
import 'package:music_player/features/player/domain/enums/playlist_source.dart';
import 'package:just_audio/just_audio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: 2,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: 2,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      pinned: false,
                      systemOverlayStyle: const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarBrightness: Brightness.dark,
                        statusBarIconBrightness: Brightness.light,
                        systemNavigationBarColor: Colors.transparent,
                        systemStatusBarContrastEnforced: false,
                      ),
                      title: const Text('Müzik Oynatıcı'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        CustomTabBar(controller: _tabController),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _KeepAlivePage(
                      child: const RecentlyPlayedPage(
                          key: PageStorageKey('recently_played')),
                    ),
                    _KeepAlivePage(
                      child: const MostPlayedPage(
                          key: PageStorageKey('most_played')),
                    ),
                    _KeepAlivePage(
                      child: BlocBuilder<MediaCubit, MediaState>(
                        buildWhen: (previous, current) =>
                            previous.songs != current.songs,
                        builder: (context, state) {
                          return MediaList(
                            key: const PageStorageKey('all_songs'),
                            mediaItems: state.songs,
                            isGridView: false,
                            onItemTap: (track) {
                              context.read<AudioPlayerCubit>().play(
                                    track,
                                    playlist: state.songs,
                                    source: PlaylistSource.allSongs,
                                  );
                            },
                          );
                        },
                      ),
                    ),
                    const FavoritesList(key: PageStorageKey('favorites')),
                    const AlbumList(key: PageStorageKey('albums')),
                    const FolderList(key: PageStorageKey('folders')),
                  ],
                ),
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final CustomTabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// TabBarView içindeki sayfaları AutomaticKeepAliveClientMixin ile sarmalayalım
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
