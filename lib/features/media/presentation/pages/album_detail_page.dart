import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../cubit/media_cubit.dart';
import '../../data/models/custom_album.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import 'dart:io';
import '../../../player/domain/enums/playlist_source.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/sort_type.dart';
import '../widgets/sort_options_sheet.dart';
import '../widgets/media_list.dart';
import '../widgets/cached_artwork.dart';
import 'package:music_player/core/extensions/list_item_style.dart';

class AlbumDetailPage extends StatefulWidget {
  final CustomAlbum album;
  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  MediaSortType _sortType = MediaSortType.title;
  SortOrder _sortOrder = SortOrder.ascending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Kapak Fotoğrafını Değiştir'),
                    onTap: () => _changeAlbumCover(context),
                  ),
                  PopupMenuItem(
                    child: const Text('Albümü Düzenle'),
                    onTap: () => _editAlbum(context),
                  ),
                  PopupMenuItem(
                    child: const Text('Albümü Sil'),
                    onTap: () => _deleteAlbum(context),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.album.name),
              background: widget.album.coverPath != null
                  ? Image.file(
                      File(widget.album.coverPath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.primary,
                      child: const Center(
                        child: Icon(
                          Icons.album,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<MediaCubit, MediaState>(
                    builder: (context, state) {
                      final songs = state.customAlbums[widget.album] ?? [];
                      final totalDuration = songs.fold<Duration>(
                        Duration.zero,
                        (total, song) =>
                            total + Duration(milliseconds: song.duration ?? 0),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${songs.length} şarkı'),
                          Text(
                              'Toplam süre: ${_formatDuration(totalDuration)}'),
                          Text(
                              'Oluşturulma: ${_formatDate(widget.album.createdAt)}'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(),
          ),
          BlocBuilder<MediaCubit, MediaState>(
            builder: (context, state) {
              final songs = state.customAlbums[widget.album] ?? [];
              final sortedSongs = _sortSongs(songs);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.sort),
                        title: const Text('Sıralama'),
                        onTap: () => _showSortOptions(context),
                      );
                    }

                    final song = sortedSongs[index - 1];

                    return Builder(
                      builder: (context) {
                        final isPlaying =
                            context.select<AudioPlayerCubit, bool>(
                          (cubit) => cubit.state.currentSong?.id == song.id,
                        );

                        return ListTile(
                          contentPadding: ListItemStyle.listItemPadding,
                          leading: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Container(
                              width: ListItemStyle.artworkSize,
                              height: ListItemStyle.artworkSize,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(
                                    ListItemStyle.artworkBorderRadius),
                              ),
                              child: Icon(
                                Icons.music_note,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isPlaying
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : null,
                              fontWeight: isPlaying ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Text(
                            song.artist ?? 'Bilinmeyen Sanatçı',
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
                            _formatDuration(
                                Duration(milliseconds: song.duration ?? 0)),
                            style: TextStyle(
                              color: isPlaying
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                            ),
                          ),
                          onTap: () {
                            context.read<AudioPlayerCubit>().play(
                                  song,
                                  playlist: songs,
                                  source: PlaylistSource.album,
                                );
                          },
                        ).withListItemStyle(
                          context: context,
                          isPlaying: isPlaying,
                        );
                      },
                    );
                  },
                  childCount: songs.length + 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changeAlbumCover(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Parçalardan Seç'),
            onTap: () => _selectCoverFromSongs(context),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeriden Seç'),
            onTap: () => _selectCoverFromGallery(context),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCoverFromSongs(BuildContext context) async {
    final songs =
        context.read<MediaCubit>().state.customAlbums[widget.album] ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              leading: QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                nullArtworkWidget: const Icon(Icons.music_note),
              ),
              title: Text(song.title),
              onTap: () {
                context.read<MediaCubit>().updateAlbumCover(
                      albumId: widget.album.id,
                      songId: song.id,
                    );
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectCoverFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      context.read<MediaCubit>().updateAlbumCover(
            albumId: widget.album.id,
            imagePath: image.path,
          );
    }
  }

  void _editAlbum(BuildContext context) {
    // Implementation of editing album
  }

  void _deleteAlbum(BuildContext context) {
    // Implementation of deleting album
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours saat ${minutes}dk ${seconds}sn';
    }
    return '${minutes}dk ${seconds}sn';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
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

  List<SongModel> _sortSongs(List<SongModel> songs) {
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
            .sort((a, b) => (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0));
        break;
      case MediaSortType.album:
        sortedSongs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case MediaSortType.size:
        sortedSongs.sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0));
        break;
    }
    if (_sortOrder == SortOrder.descending) {
      return sortedSongs.reversed.toList();
    }
    return sortedSongs;
  }
}
