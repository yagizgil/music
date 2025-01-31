import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Media extends Equatable {
  final SongModel song;
  final bool isFavorite;

  const Media({
    required this.song,
    this.isFavorite = false,
  });

  Media copyWith({
    SongModel? song,
    bool? isFavorite,
  }) {
    return Media(
      song: song ?? this.song,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [song, isFavorite];
}
