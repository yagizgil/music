import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/media_cubit.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCubit, MediaState>(
      builder: (context, state) {
        if (state.status == MediaStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == MediaStatus.failure) {
          return Center(child: Text('Hata: ${state.error}'));
        }

        if (state.folders.isEmpty) {
          return const Center(child: Text('Klasör bulunamadı'));
        }

        return ListView.builder(
          itemCount: state.folders.length,
          itemBuilder: (context, index) {
            final folder = state.folders[index];
            final folderName = folder.split('/').last;
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.folder, size: 48),
              title: Text(
                folderName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                  BlocBuilder<MediaCubit, MediaState>(
                    builder: (context, state) {
                      final trackCount = state.getFolderTrackCount(folder);
                      return Text(
                        '$trackCount parça',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                context.read<MediaCubit>().selectFolder(folder);
                Navigator.pushNamed(
                  context,
                  '/folder-detail',
                  arguments: folder,
                );
              },
            );
          },
        );
      },
    );
  }
}
