import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';

class SongList extends StatefulWidget {
  const SongList({super.key});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  bool _isSelectionMode = false;
  final Set<SongModel> _selectedSongs = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCubit, MediaState>(
      builder: (context, state) {
        if (state.status == MediaStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: _isSelectionMode ? _buildSelectionAppBar() : null,
          body: ListView.builder(
            itemCount: state.songs.length,
            itemBuilder: (context, index) {
              final song = state.songs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                title: Text(song.title),
                subtitle: Text(song.artist ?? 'Bilinmeyen Sanatçı'),
                selected: _selectedSongs.contains(song),
                onLongPress: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedSongs.add(song);
                  });
                },
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
                    : () {
                        // Normal şarkı çalma işlemi
                      },
              );
            },
          ),
          floatingActionButton: _isSelectionMode
              ? FloatingActionButton(
                  onPressed: () {
                    _showAddToAlbumDialog(context);
                  },
                  child: const Icon(Icons.playlist_add),
                )
              : null,
        );
      },
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedSongs.length} şarkı seçildi'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedSongs.clear();
          });
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.playlist_add),
          onPressed: () {
            _showAddToAlbumDialog(context);
          },
        ),
      ],
    );
  }

  Future<void> _showAddToAlbumDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albüme Ekle'),
        content: Column(
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
            SizedBox(
              height: 200,
              child: BlocBuilder<MediaCubit, MediaState>(
                builder: (context, state) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.albums.length,
                    itemBuilder: (context, index) {
                      final album = state.albums[index];
                      return ListTile(
                        leading: QueryArtworkWidget(
                          id: album.id,
                          type: ArtworkType.ALBUM,
                          nullArtworkWidget: const Icon(Icons.album),
                        ),
                        title: Text(album.album),
                        onTap: () {
                          // Seçili şarkıları mevcut albüme ekle
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
                // Yeni albüm oluştur ve seçili şarkıları ekle
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
