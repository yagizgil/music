import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/media_cubit.dart';
import '../../data/models/search_filter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final Set<SearchFilter> _selectedFilters = {SearchFilter.media};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ara...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            // Arama işlemini başlat
            _performSearch(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: BlocBuilder<MediaCubit, MediaState>(
        builder: (context, state) {
          if (state.status == MediaStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Arama sonuçlarını göster
          return ListView.builder(
            itemCount: state.searchResults.length,
            itemBuilder: (context, index) {
              final result = state.searchResults[index];
              return ListTile(
                title: Text(result.title),
                subtitle: Text(result.subtitle),
                leading: result.icon,
                onTap: () => result.onTap?.call(),
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Arama Filtreleri'),
                trailing: TextButton(
                  child: const Text('Tümünü Seç'),
                  onPressed: () {
                    setState(() {
                      _selectedFilters.addAll(SearchFilter.values);
                    });
                    _performSearch(_searchController.text);
                  },
                ),
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text('Medyalarda Ara'),
                value: _selectedFilters.contains(SearchFilter.media),
                onChanged: (value) => _updateFilter(SearchFilter.media, value),
              ),
              CheckboxListTile(
                title: const Text('Favorilerde Ara'),
                value: _selectedFilters.contains(SearchFilter.favorites),
                onChanged: (value) =>
                    _updateFilter(SearchFilter.favorites, value),
              ),
              CheckboxListTile(
                title: const Text('Albüm İsimlerinde Ara'),
                value: _selectedFilters.contains(SearchFilter.albumNames),
                onChanged: (value) =>
                    _updateFilter(SearchFilter.albumNames, value),
              ),
              CheckboxListTile(
                title: const Text('Albüm İçeriklerinde Ara'),
                value: _selectedFilters.contains(SearchFilter.albumContents),
                onChanged: (value) =>
                    _updateFilter(SearchFilter.albumContents, value),
              ),
              CheckboxListTile(
                title: const Text('Klasör İsimlerinde Ara'),
                value: _selectedFilters.contains(SearchFilter.folderNames),
                onChanged: (value) =>
                    _updateFilter(SearchFilter.folderNames, value),
              ),
              CheckboxListTile(
                title: const Text('Klasör İçeriklerinde Ara'),
                value: _selectedFilters.contains(SearchFilter.folderContents),
                onChanged: (value) =>
                    _updateFilter(SearchFilter.folderContents, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateFilter(SearchFilter filter, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedFilters.add(filter);
      } else {
        _selectedFilters.remove(filter);
      }
    });
    _performSearch(_searchController.text);
  }

  void _performSearch(String query) {
    context.read<MediaCubit>().search(
          query: query,
          filters: _selectedFilters,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
