import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/media_cubit.dart';
import '../widgets/media_list.dart';
import '../widgets/sort_options_sheet.dart';
import '../../data/models/sort_type.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/domain/enums/playlist_source.dart';

class FolderDetailPage extends StatefulWidget {
  final String folderPath;

  const FolderDetailPage({
    super.key,
    required this.folderPath,
  });

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.folderPath.split('/').last),
            Text(
              widget.folderPath,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<MediaCubit, MediaState>(
        builder: (context, state) {
          final tracks =
              context.read<MediaCubit>().getFolderTracks(widget.folderPath);

          return MediaList(
            mediaItems: tracks,
            isGridView: _isGridView,
            onItemTap: (track) {
              context.read<AudioPlayerCubit>().play(
                    track,
                    playlist: tracks,
                    source: PlaylistSource.folder,
                  );
            },
          );
        },
      ),
    );
  }
}
