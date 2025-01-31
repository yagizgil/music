import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';
import '../pages/album_detail_page.dart';
import '../../data/models/custom_album.dart';
import 'dart:io';
import '../../data/models/sort_type.dart';
import '../../../../core/extensions/bottom_sheet_style.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList>
    with AutomaticKeepAliveClientMixin {
  bool _isSelectionMode = false;
  final Set<CustomAlbum> _selectedAlbums = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<MediaCubit, MediaState>(
      builder: (context, state) {
        if (state.status == MediaStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customAlbums = state.customAlbums.keys.toList();

        if (customAlbums.isEmpty) {
          return const Center(child: Text('Henüz albüm oluşturmadınız'));
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => _showSortOptions(context),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = customAlbums[index];
                  final songs = state.customAlbums[album] ?? [];

                  return ListTile(
                    leading: album.coverPath != null
                        ? Image.file(
                            File(album.coverPath!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.album, color: Colors.white),
                          ),
                    title: Text(album.name),
                    subtitle: Text('${songs.length} şarkı'),
                    selected: _selectedAlbums.contains(album),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            state.pinnedAlbums.contains(album.id)
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: state.pinnedAlbums.contains(album.id)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: () {
                            context.read<MediaCubit>().togglePinAlbum(album.id);
                          },
                        ),
                      ],
                    ),
                    onLongPress: () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedAlbums.add(album);
                      });
                    },
                    onTap: _isSelectionMode
                        ? () {
                            setState(() {
                              if (_selectedAlbums.contains(album)) {
                                _selectedAlbums.remove(album);
                                if (_selectedAlbums.isEmpty) {
                                  _isSelectionMode = false;
                                }
                              } else {
                                _selectedAlbums.add(album);
                              }
                            });
                          }
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AlbumDetailPage(album: album),
                              ),
                            );
                          },
                  );
                },
                childCount: customAlbums.length,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlocBuilder<MediaCubit, MediaState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'Sıralama',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                ListTile(
                  title: const Text('İsme Göre'),
                  leading: const Icon(Icons.sort_by_alpha),
                  trailing: Radio<MediaSortType>(
                    value: MediaSortType.title,
                    groupValue: state.albumSortType,
                    onChanged: (MediaSortType? value) {
                      if (value != null) {
                        context.read<MediaCubit>().changeAlbumSortType(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  tileColor: state.albumSortType == MediaSortType.title
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3)
                      : null,
                ),
                ListTile(
                  title: const Text('Eklenme Tarihine Göre'),
                  leading: const Icon(Icons.date_range),
                  trailing: Radio<MediaSortType>(
                    value: MediaSortType.dateAdded,
                    groupValue: state.albumSortType,
                    onChanged: (MediaSortType? value) {
                      if (value != null) {
                        context.read<MediaCubit>().changeAlbumSortType(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  tileColor: state.albumSortType == MediaSortType.dateAdded
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3)
                      : null,
                ),
                ListTile(
                  title: const Text('Parça Sayısına Göre'),
                  leading: const Icon(Icons.format_list_numbered),
                  trailing: Radio<MediaSortType>(
                    value: MediaSortType.size,
                    groupValue: state.albumSortType,
                    onChanged: (MediaSortType? value) {
                      if (value != null) {
                        context.read<MediaCubit>().changeAlbumSortType(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  tileColor: state.albumSortType == MediaSortType.size
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3)
                      : null,
                ),
                Divider(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                ListTile(
                  title: Text(
                    state.albumSortOrder == SortOrder.ascending
                        ? 'Artan'
                        : 'Azalan',
                  ),
                  leading: Icon(
                    state.albumSortOrder == SortOrder.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    context.read<MediaCubit>().toggleAlbumSortOrder();
                    Navigator.pop(context);
                  },
                  tileColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedAlbums.length} seçildi'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedAlbums.clear();
          });
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _showEditAlbumDialog(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            _showDeleteConfirmationDialog(context);
          },
        ),
      ],
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final songs = _getSelectedAlbumSongs(context);

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
                      songs: songs,
                    );
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = false;
                  _selectedAlbums.clear();
                });
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  List<SongModel> _getSelectedAlbumSongs(BuildContext context) {
    final songs = <SongModel>{};
    final state = context.read<MediaCubit>().state;

    for (var album in _selectedAlbums) {
      songs.addAll(
        state.songs.where((song) => song.albumId == album.id),
      );
    }

    return songs.toList();
  }

  Future<void> _showEditAlbumDialog(BuildContext context) async {
    // Albüm düzenleme dialogu
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albümleri Sil'),
        content: Text(
          '${_selectedAlbums.length} albümü silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<MediaCubit>().deleteCustomAlbums(
                    _selectedAlbums.map((album) => album.id).toList(),
                  );
              Navigator.pop(context);
              setState(() {
                _isSelectionMode = false;
                _selectedAlbums.clear();
              });
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
