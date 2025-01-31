import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/media_cubit.dart';
import 'package:flutter/rendering.dart';

class MostPlayedList extends StatefulWidget {
  const MostPlayedList({super.key});

  @override
  State<MostPlayedList> createState() => _MostPlayedListState();
}

class _MostPlayedListState extends State<MostPlayedList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<MediaCubit, MediaState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Şimdilik boş liste gösterelim
        return const Center(
          child: Text('Henüz en çok oynatılan medya yok'),
        );
      },
    );
  }
}
