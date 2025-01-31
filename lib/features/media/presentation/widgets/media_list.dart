import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:typed_data'; // Uint8List için bu import gerekli
import '../cubit/media_cubit.dart';
import '../../data/models/sort_type.dart' show MediaSortType, SortOrder;
import '../../data/models/view_options.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/domain/enums/playlist_source.dart';
import 'sort_options_sheet.dart';
import 'package:flutter/rendering.dart';
import '../../data/services/cache_manager.dart';
import 'scrollable_media_row.dart';
import 'package:music_player/core/utils/duration_formatter.dart';
import 'package:music_player/core/extensions/list_item_style.dart';
import 'cached_artwork.dart';
import 'dart:io';
import 'scroll_to_top_button.dart';

class MediaList extends StatefulWidget {
  final List<SongModel> mediaItems;
  final bool isGridView;
  final Function(SongModel) onItemTap;

  const MediaList({
    super.key,
    required this.mediaItems,
    required this.isGridView,
    required this.onItemTap,
  });

  @override
  State<MediaList> createState() => _MediaListState();
}

class _MediaListState extends State<MediaList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = false; // Grid/List durumunu tutmak için
  bool _isSelectionMode = false;
  final Set<SongModel> _selectedSongs = {};
  MediaSortType _sortType = MediaSortType.dateAdded;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  bool get wantKeepAlive => true; // Tab'lar arası geçişte state'i koru

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Column(
        children: [
          // Üst bar - Sıralama ve görünüm seçenekleri
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortOptions(context),
                  tooltip: 'Sıralama',
                ),
                IconButton(
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  tooltip: _isGridView ? 'Liste Görünümü' : 'Grid Görünümü',
                ),
              ],
            ),
          ),
          // Liste/Grid görünümü
          Expanded(
            child: BlocBuilder<MediaCubit, MediaState>(
              builder: (context, state) {
                if (state.status == MediaStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == MediaStatus.failure) {
                  return Center(child: Text('Hata: ${state.error}'));
                }

                if (widget.mediaItems.isEmpty) {
                  return const Center(child: Text('Medya bulunamadı'));
                }

                final sortedItems = _getSortedSongs(widget.mediaItems);

                return _isGridView
                    ? _buildGridView(sortedItems)
                    : _buildListView(sortedItems);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScrollToTopButton(
        scrollController: _scrollController,
      ),
    );
  }

  Widget _buildListView(List<SongModel> songs) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return MediaListItem(
          song: song,
          playlist: songs,
          playlistName: 'Tüm Şarkılar',
          isSelected: _isSelectionMode && _selectedSongs.contains(song),
          onTap: _isSelectionMode
              ? () {
                  setState(() {
                    if (_selectedSongs.contains(song)) {
                      _selectedSongs.remove(song);
                      if (_selectedSongs.isEmpty) {
                        _isSelectionMode = false;
                      }
                    } else {
                      _selectedSongs.add(song);
                    }
                  });
                }
              : () => widget.onItemTap(song),
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedSongs.add(song);
            });
          },
        );
      },
    );
  }

  Widget _buildGridView(List<SongModel> songs) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onItemTap(song),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CachedArtwork(
                    id: song.id,
                    size: 200,
                    borderRadius: 0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        song.artist ?? 'Bilinmeyen Sanatçı',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SongModel> _getSortedSongs(List<SongModel> songs) {
    final sortedSongs = List<SongModel>.from(songs);

    switch (_sortType) {
      case MediaSortType.title:
        sortedSongs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case MediaSortType.artist:
        sortedSongs.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
        break;
      case MediaSortType.duration:
        sortedSongs
            .sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
        break;
      case MediaSortType.dateAdded:
        sortedSongs
            .sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
      case MediaSortType.album:
        sortedSongs.sort((a, b) => (a.album ?? '').compareTo(b.album ?? ''));
        break;
      case MediaSortType.size:
        sortedSongs.sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0));
        break;
    }

    if (_sortType != MediaSortType.dateAdded &&
        _sortOrder == SortOrder.descending) {
      return sortedSongs.reversed.toList();
    }
    return sortedSongs;
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortOptionsSheet(
        sortType: _sortType,
        sortOrder: _sortOrder,
        onSortTypeChanged: (type) {
          setState(() => _sortType = type);
          Navigator.pop(context);
        },
        onSortOrderChanged: (order) {
          setState(() => _sortOrder = order);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showAddToAlbumDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Yeni Albüm Oluştur'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAlbumDialog(context);
                },
              ),
              const Divider(),
              Expanded(
                child: BlocBuilder<MediaCubit, MediaState>(
                  builder: (context, state) {
                    final albums = state.customAlbums.keys.toList();
                    if (albums.isEmpty) {
                      return const Center(child: Text('Henüz albüm yok'));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return ListTile(
                          leading: album.coverPath != null
                              ? Image.file(
                                  File(album.coverPath!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.album),
                          title: Text(album.name),
                          subtitle: Text(
                              '${state.customAlbums[album]?.length ?? 0} şarkı'),
                          onTap: () {
                            context.read<MediaCubit>().addSongsToAlbum(
                                  albumId: album.id,
                                  songs: _selectedSongs.toList(),
                                );
                            Navigator.pop(context);
                            setState(() {
                              _isSelectionMode = false;
                              _selectedSongs.clear();
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateAlbumDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Albüm Oluştur'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Albüm Adı',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<MediaCubit>().createAlbumWithSongs(
                      name: controller.text,
                      songs: _selectedSongs.toList(),
                    );
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = false;
                  _selectedSongs.clear();
                });
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}

class MediaListItem extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final String playlistName;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const MediaListItem({
    super.key,
    required this.song,
    required this.playlist,
    required this.playlistName,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select<AudioPlayerCubit, bool>(
      (cubit) => cubit.state.currentSong?.id == song.id,
    );

    return RepaintBoundary(
      child: ListTile(
        contentPadding: ListItemStyle.listItemPadding,
        selected: isSelected,
        leading: CachedArtwork(
          key: ValueKey('artwork_${song.id}'),
          id: song.id,
          size: ListItemStyle.artworkSize,
          borderRadius: ListItemStyle.artworkBorderRadius,
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPlaying
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
            fontWeight: isPlaying ? FontWeight.bold : null,
          ),
        ),
        subtitle: Text(
          subtitle ?? song.artist ?? 'Bilinmeyen Sanatçı',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPlaying
                ? Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withOpacity(0.7)
                : null,
          ),
        ),
        trailing: Text(
          _formatDuration(Duration(milliseconds: song.duration ?? 0)),
          style: TextStyle(
            color: isPlaying
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ).withListItemStyle(
        context: context,
        isPlaying: isPlaying,
        isSelected: isSelected,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
