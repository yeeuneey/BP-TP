import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../movies/models/search_filters.dart';
import '../movies/models/tmdb_movie.dart';
import '../movies/providers/search_controller.dart' as search;
import '../root/widgets/yeemin_app_bar.dart';
import '../wishlist/data/wishlist_repository.dart';
import '../wishlist/providers/wishlist_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  _OpenFilter? _openFilter;

  static const _sortOptions = [
    _SearchOption(SearchSort.popular, '인기순'),
    _SearchOption(SearchSort.latest, '최신순'),
    _SearchOption(SearchSort.rating, '평점순'),
    _SearchOption(SearchSort.title, '제목순'),
  ];

  static const _genreOptions = [
    _SearchOption(SearchGenre.all, '전체'),
    _SearchOption(SearchGenre.action, '액션'),
    _SearchOption(SearchGenre.adventure, '어드벤처'),
    _SearchOption(SearchGenre.animation, '애니메이션'),
    _SearchOption(SearchGenre.comedy, '코미디'),
    _SearchOption(SearchGenre.crime, '범죄'),
    _SearchOption(SearchGenre.drama, '드라마'),
    _SearchOption(SearchGenre.fantasy, '판타지'),
    _SearchOption(SearchGenre.horror, '공포'),
    _SearchOption(SearchGenre.romance, '로맨스'),
    _SearchOption(SearchGenre.scifi, 'SF'),
    _SearchOption(SearchGenre.thriller, '스릴러'),
  ];

  static const _languageOptions = [
    _SearchOption(SearchLanguage.all, '전체'),
    _SearchOption(SearchLanguage.ko, '한국어'),
    _SearchOption(SearchLanguage.en, '영어'),
    _SearchOption(SearchLanguage.ja, '일본어'),
  ];

  static const _yearOptions = [
    _SearchOption(SearchYearRange.all, '전체'),
    _SearchOption(SearchYearRange.y2020plus, '2020년 이후'),
    _SearchOption(SearchYearRange.y2010s, '2010-2019'),
    _SearchOption(SearchYearRange.y2000s, '2000-2009'),
    _SearchOption(SearchYearRange.y1990s, '1990-1999'),
    _SearchOption(SearchYearRange.pre1990, '1990년 이전'),
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(search.searchControllerProvider);
    _queryController.text = state.query;
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final state = ref.read(search.searchControllerProvider);
    if (!state.active || state.loading || !state.hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.82) {
      ref.read(search.searchControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _runSearch({SearchSort? sort}) async {
    final ctrl = ref.read(search.searchControllerProvider.notifier);
    ctrl.setQuery(_queryController.text.trim());
    await ctrl.search(overrideSort: sort);
    setState(() => _openFilter = null);
  }

  void _resetFilters() {
    setState(() => _openFilter = null);
    ref.read(search.searchControllerProvider.notifier).reset();
    _queryController.clear();
  }

  Future<void> _toggleWishlist(
    TmdbMovie movie,
    Map<int, WishlistItem> wishlistMap,
  ) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final existing = wishlistMap[movie.id];
    final poster = movie.posterUrl(size: 'w342');
    try {
      if (existing != null) {
        await repo.remove(existing.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에서 삭제했어요.')),
        );
      } else {
        await repo.add(movie.id, movie.title, poster);
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에 추가했어요.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('처리에 실패했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).brightness == Brightness.dark ? _Palette.dark : _Palette.light;
    final state = ref.watch(search.searchControllerProvider);
    final wishlist = ref.watch(wishlistStreamProvider);
    final Map<int, WishlistItem> wishlistMap = {
      for (final item in wishlist.value ?? []) item.movieId: item,
    };
    final results = state.active ? state.results : const <TmdbMovie>[];

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const YeeminAppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _openFilter = null),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchRow(palette),
                    const SizedBox(height: 14),
                    _buildSortChips(palette, state),
                    const SizedBox(height: 16),
                    _buildFilters(palette, state),
                    const SizedBox(height: 14),
                    Text(
                      '검색 결과',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.error != null && results.isNotEmpty)
                      _ErrorBanner(text: state.error!, palette: palette),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            ..._buildResultsSliver(palette, state, results, wishlistMap),
            SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(_Palette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '검색',
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                style: TextStyle(color: palette.text),
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  hintStyle: TextStyle(color: palette.muted),
                  filled: true,
                  fillColor: palette.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: palette.accent),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(search.searchControllerProvider.notifier).setQuery(v),
                onSubmitted: (_) {
                  _runSearch();
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.card,
                foregroundColor: palette.text,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: palette.border),
                ),
              ),
              onPressed: () {
                _runSearch();
              },
              child: const Text(
                '검색',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChips(_Palette palette, search.SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정렬',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _sortOptions)
              ChoiceChip(
                label: Text(
                  option.label,
                  style: TextStyle(
                    color: state.sort == option.value ? Colors.white : palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: state.sort == option.value,
                selectedColor: palette.accent,
                backgroundColor: palette.card,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: state.sort == option.value ? palette.accent : palette.border,
                  ),
                ),
                onSelected: (_) {
                  _runSearch(sort: option.value);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(_Palette palette, search.SearchState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '필터',
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('필터 초기화'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _FilterSelect<SearchGenre>(
                    palette: palette,
                    label: '장르',
                    value: state.genre,
                    open: _openFilter == _OpenFilter.genre,
                    options: _genreOptions,
                    onToggle: () {
                      setState(() {
                        _openFilter = _openFilter == _OpenFilter.genre
                            ? null
                            : _OpenFilter.genre;
                      });
                    },
                    onSelect: (value) {
                      ref.read(search.searchControllerProvider.notifier).setGenre(value);
                      _runSearch();
                    },
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _FilterSelect<SearchLanguage>(
                    palette: palette,
                    label: '언어',
                    value: state.language,
                    open: _openFilter == _OpenFilter.language,
                    options: _languageOptions,
                    onToggle: () {
                      setState(() {
                        _openFilter =
                            _openFilter == _OpenFilter.language ? null : _OpenFilter.language;
                      });
                    },
                    onSelect: (value) {
                      ref
                          .read(search.searchControllerProvider.notifier)
                          .setLanguage(value);
                      _runSearch();
                    },
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _FilterSelect<SearchYearRange>(
                    palette: palette,
                    label: '개봉 연도',
                    value: state.year,
                    open: _openFilter == _OpenFilter.year,
                    options: _yearOptions,
                    onToggle: () {
                      setState(() {
                        _openFilter = _openFilter == _OpenFilter.year ? null : _OpenFilter.year;
                      });
                    },
                    onSelect: (value) {
                      ref.read(search.searchControllerProvider.notifier).setYear(value);
                      _runSearch();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildResultsSliver(
    _Palette palette,
    search.SearchState state,
    List<TmdbMovie> results,
    Map<int, WishlistItem> wishlistMap,
  ) {
    if (state.loading && results.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: palette.accent),
          ),
        ),
      ];
    }

    if (!state.loading && results.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(palette: palette, active: state.active),
        ),
      ];
    }

    final showLoader = state.loading && state.hasMore;
    final itemCount = results.length + (showLoader ? 1 : 0);

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        sliver: SliverGrid.builder(
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            if (index >= results.length) {
              return _LoadMoreTile(palette: palette);
            }
            final movie = results[index];
            final picked = wishlistMap.containsKey(movie.id);
            return _MovieCard(
              palette: palette,
              movie: movie,
              picked: picked,
              onTap: () => context.go('/movie/${movie.id}'),
              onWishlistToggle: () => _toggleWishlist(movie, wishlistMap),
            );
          },
        ),
      ),
    ];
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.palette,
    required this.movie,
    required this.picked,
    required this.onTap,
    required this.onWishlistToggle,
  });

  final _Palette palette;
  final TmdbMovie movie;
  final bool picked;
  final VoidCallback onTap;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    final overview =
        movie.overview.isNotEmpty ? movie.overview : '정보가 부족합니다.';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: movie.posterPath != null && movie.posterPath!.isNotEmpty
                          ? Image.network(
                              movie.posterUrl(size: 'w342'),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _PosterPlaceholder(palette: palette),
                            )
                          : _PosterPlaceholder(palette: palette),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: picked ? palette.accent : palette.card.withAlpha((0.95 * 255).round()),
                shape: const CircleBorder(),
                elevation: 5,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onWishlistToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      picked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: picked ? Colors.white : palette.text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSelect<T> extends StatelessWidget {
  const _FilterSelect({
    required this.palette,
    required this.label,
    required this.value,
    required this.open,
    required this.options,
    required this.onToggle,
    required this.onSelect,
  });

  final _Palette palette;
  final String label;
  final T value;
  final bool open;
  final List<_SearchOption<T>> options;
  final VoidCallback onToggle;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: open ? palette.accent : palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected.label,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  color: palette.text,
                ),
              ],
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                for (final option in options)
                  InkWell(
                    onTap: () => onSelect(option.value),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      color: option.value == value ? palette.accent : palette.card,
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: option.value == value ? Colors.white : palette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text, required this.palette});

  final String text;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: palette.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(color: palette.accent, strokeWidth: 2.6),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette, required this.active});

  final _Palette palette;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final text = active
        ? '결과가 없습니다. 검색어를 입력하거나 정렬/필터를 선택하세요.'
        : '검색어를 입력하거나 정렬/필터를 골라보세요.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.border,
      alignment: Alignment.center,
      child: Icon(Icons.hide_image_outlined, color: palette.muted),
    );
  }
}

class _Palette {
  const _Palette({
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
  });

  final Color bg;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;

  static const dark = _Palette(
    bg: Color(0xFF05070F),
    card: Color(0xFF0B1021),
    border: Color(0xFF1F2937),
    text: Color(0xFFF8FAFC),
    muted: Color(0xFF9CA3AF),
    accent: Color(0xFFE50914),
  );

  static const light = _Palette(
    bg: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    text: Color(0xFF0F172A),
    muted: Color(0xFF475569),
    accent: Color(0xFFE50914),
  );
}

class _SearchOption<T> {
  const _SearchOption(this.value, this.label);
  final T value;
  final String label;
}

enum _OpenFilter { genre, language, year }
