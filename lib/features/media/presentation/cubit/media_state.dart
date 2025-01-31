part of 'media_cubit.dart';

enum MediaStatus { initial, loading, success, failure }

class SearchResult {
  final String title;
  final String subtitle;
  final Widget? icon;
  final VoidCallback? onTap;

  const SearchResult({
    required this.title,
    required this.subtitle,
    this.icon,
    this.onTap,
  });
}

class MediaState extends Equatable {
  final MediaStatus status;
  final String? error;
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<String> folders;
  final List<SongModel> favorites;
  final Map<int, int> playCount;
  final List<SongModel> recentlyPlayed;
  final Map<CustomAlbum, List<SongModel>> customAlbums;
  final Set<int> pinnedAlbums;
  final MediaSortType sortType;
  final SortOrder sortOrder;
  final MediaSortType albumSortType;
  final SortOrder albumSortOrder;
  final ViewOptions viewOptions;
  final List<SearchResult> searchResults;
  final String? selectedFolder;
  final List<SongModel> tracks;
  final Set<int> pinnedFavorites;

  bool get isLoading => status == MediaStatus.loading;

  const MediaState({
    this.status = MediaStatus.initial,
    this.error,
    this.songs = const [],
    this.albums = const [],
    this.folders = const [],
    this.favorites = const [],
    this.playCount = const {},
    this.recentlyPlayed = const [],
    this.customAlbums = const {},
    this.pinnedAlbums = const {},
    this.sortType = MediaSortType.title,
    this.sortOrder = SortOrder.ascending,
    this.albumSortType = MediaSortType.title,
    this.albumSortOrder = SortOrder.ascending,
    this.viewOptions = const ViewOptions(),
    this.searchResults = const [],
    this.selectedFolder,
    this.tracks = const [],
    this.pinnedFavorites = const {},
  });

  MediaState copyWith({
    MediaStatus? status,
    String? error,
    List<SongModel>? songs,
    List<AlbumModel>? albums,
    List<String>? folders,
    List<SongModel>? favorites,
    Map<int, int>? playCount,
    List<SongModel>? recentlyPlayed,
    Map<CustomAlbum, List<SongModel>>? customAlbums,
    Set<int>? pinnedAlbums,
    MediaSortType? sortType,
    SortOrder? sortOrder,
    MediaSortType? albumSortType,
    SortOrder? albumSortOrder,
    ViewOptions? viewOptions,
    List<SearchResult>? searchResults,
    String? selectedFolder,
    List<SongModel>? tracks,
    Set<int>? pinnedFavorites,
  }) {
    return MediaState(
      status: status ?? this.status,
      error: error ?? this.error,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      folders: folders ?? this.folders,
      favorites: favorites ?? this.favorites,
      playCount: playCount ?? this.playCount,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      customAlbums: customAlbums ?? this.customAlbums,
      pinnedAlbums: pinnedAlbums ?? this.pinnedAlbums,
      sortType: sortType ?? this.sortType,
      sortOrder: sortOrder ?? this.sortOrder,
      albumSortType: albumSortType ?? this.albumSortType,
      albumSortOrder: albumSortOrder ?? this.albumSortOrder,
      viewOptions: viewOptions ?? this.viewOptions,
      searchResults: searchResults ?? this.searchResults,
      selectedFolder: selectedFolder ?? this.selectedFolder,
      tracks: tracks ?? this.tracks,
      pinnedFavorites: pinnedFavorites ?? this.pinnedFavorites,
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        songs,
        albums,
        folders,
        favorites,
        playCount,
        recentlyPlayed,
        customAlbums,
        pinnedAlbums,
        sortType,
        sortOrder,
        albumSortType,
        albumSortOrder,
        viewOptions,
        searchResults,
        selectedFolder,
        tracks,
        pinnedFavorites,
      ];

  int getFolderTrackCount(String folderPath) {
    return tracks.where((track) => track.path.startsWith(folderPath)).length;
  }
}
