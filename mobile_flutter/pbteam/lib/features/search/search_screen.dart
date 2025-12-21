import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../movies/models/search_filters.dart';
import '../movies/providers/search_controller.dart';
import '../movies/widgets/movie_list.dart';
import '../wishlist/widgets/wishlist_add_button.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search movies...',
              ),
              onChanged: controller.setQuery,
              onSubmitted: (_) => controller.search(),
            ),
          ),
          _Filters(state: state, onChange: controller),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification &&
                    n.metrics.pixels >= n.metrics.maxScrollExtent * 0.7) {
                  controller.loadMore();
                }
                return false;
              },
              child: Builder(
                builder: (context) {
                  if (state.loading && state.results.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null && state.results.isEmpty) {
                    return Center(child: Text('Error: ${state.error}'));
                  }
                  if (!state.active && state.results.isEmpty) {
                    return const Center(child: Text('Start typing to search'));
                  }
                  return MovieList(
                    movies: state.results,
                    onTap: (m) => context.go('/movie/${m.id}'),
                    trailingBuilder: (m) => WishlistAddButton(movie: m),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.onChange});

  final SearchState state;
  final SearchController onChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _dropdown<SearchSort>(
            label: 'Sort',
            value: state.sort,
            items: const {
              SearchSort.popular: 'Popular',
              SearchSort.latest: 'Latest',
              SearchSort.rating: 'Rating',
              SearchSort.title: 'Title',
            },
            onChanged: (v) => v != null ? onChange.search(overrideSort: v) : null,
          ),
          const SizedBox(width: 8),
          _dropdown<SearchGenre>(
            label: 'Genre',
            value: state.genre,
            items: const {
              SearchGenre.all: 'All',
              SearchGenre.action: 'Action',
              SearchGenre.adventure: 'Adventure',
              SearchGenre.animation: 'Animation',
              SearchGenre.comedy: 'Comedy',
              SearchGenre.crime: 'Crime',
              SearchGenre.drama: 'Drama',
              SearchGenre.fantasy: 'Fantasy',
              SearchGenre.horror: 'Horror',
              SearchGenre.romance: 'Romance',
              SearchGenre.scifi: 'Sci-Fi',
              SearchGenre.thriller: 'Thriller',
            },
            onChanged: (v) {
              if (v != null) {
                onChange.setGenre(v);
                onChange.search();
              }
            },
          ),
          const SizedBox(width: 8),
          _dropdown<SearchLanguage>(
            label: 'Lang',
            value: state.language,
            items: const {
              SearchLanguage.all: 'All',
              SearchLanguage.ko: 'Korean',
              SearchLanguage.en: 'English',
              SearchLanguage.ja: 'Japanese',
            },
            onChanged: (v) {
              if (v != null) {
                onChange.setLanguage(v);
                onChange.search();
              }
            },
          ),
          const SizedBox(width: 8),
          _dropdown<SearchYearRange>(
            label: 'Year',
            value: state.year,
            items: const {
              SearchYearRange.all: 'All',
              SearchYearRange.y2020plus: '2020+',
              SearchYearRange.y2010s: '2010s',
              SearchYearRange.y2000s: '2000s',
              SearchYearRange.y1990s: '1990s',
              SearchYearRange.pre1990: '<1990',
            },
            onChanged: (v) {
              if (v != null) {
                onChange.setYear(v);
                onChange.search();
              }
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => onChange.reset(),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 6),
        DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
