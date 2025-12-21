import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../movies/models/tmdb_movie.dart';
import '../movies/providers/now_playing_provider.dart';
import '../movies/providers/popular_provider.dart';
import '../movies/providers/search_controller.dart' as search;
import '../movies/providers/top_rated_provider.dart';
import '../root/widgets/yeemin_app_bar.dart';
import '../wishlist/data/wishlist_repository.dart';
import '../wishlist/providers/wishlist_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette =
        Theme.of(context).brightness == Brightness.dark ? _Palette.dark : _Palette.light;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const YeeminAppBar(),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody();

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  final _searchText = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = ref.read(search.searchControllerProvider).query;
    _searchText.text = initial;
  }

  @override
  void dispose() {
    _searchText.dispose();
    super.dispose();
  }

  Future<void> _toggleWishlist(
    TmdbMovie movie,
    Map<int, WishlistItem> wishlistMap,
  ) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final existing = wishlistMap[movie.id];
    try {
      if (existing != null) {
        await repo.remove(existing.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에서 제거했어요')),
        );
      } else {
        await repo.add(movie.id, movie.title, movie.posterUrl(size: 'w342'));
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에 추가했어요')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('처리 실패: $e')),
      );
    }
  }

  Future<void> _runSearch() async {
    final query = _searchText.text.trim();
    final ctrl = ref.read(search.searchControllerProvider.notifier);
    ctrl.setQuery(query);
    await ctrl.search();
    if (mounted) context.go('/search');
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).brightness == Brightness.dark ? _Palette.dark : _Palette.light;
    final nowPlaying = ref.watch(nowPlayingProvider);
    final topRated = ref.watch(topRatedProvider);
    final popular = ref.watch(popularMoviesProvider);
    final wishlistAsync = ref.watch(wishlistStreamProvider);

    final wishlistMap = <int, WishlistItem>{};
    if (wishlistAsync.hasValue) {
      for (final item in wishlistAsync.value!) {
        wishlistMap[item.movieId] = item;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroSection(
            palette: palette,
            searchController: _searchText,
            onSearch: _runSearch,
          ),
          const SizedBox(height: 12),
          if (wishlistAsync.isLoading) const LinearProgressIndicator(minHeight: 2),
          _HomeSection(
            title: '요즘 뜨는 영화',
            movies: popular,
            palette: palette,
            wishlistMap: wishlistMap,
            onWishlistToggle: (m) => _toggleWishlist(m, wishlistMap),
          ),
          const SizedBox(height: 16),
          _HomeSection(
            title: '지금 극장에서 상영 중',
            movies: nowPlaying,
            palette: palette,
            wishlistMap: wishlistMap,
            onWishlistToggle: (m) => _toggleWishlist(m, wishlistMap),
          ),
          const SizedBox(height: 16),
          _HomeSection(
            title: '평점 높은 영화',
            movies: topRated,
            palette: palette,
            wishlistMap: wishlistMap,
            onWishlistToggle: (m) => _toggleWishlist(m, wishlistMap),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.palette,
    required this.searchController,
    required this.onSearch,
  });

  final _Palette palette;
  final TextEditingController searchController;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOR YOU',
          style: TextStyle(
            color: palette.muted,
            letterSpacing: 2,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'TMDB API로부터 가져온 추천',
          style: TextStyle(
            color: palette.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '장르/평점/연도 필터 없이 빠르게 둘러보고,\n검색하면 바로 Search 탭으로 이동해요.',
          style: TextStyle(
            color: palette.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
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
                onSubmitted: (_) => onSearch(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.card,
                foregroundColor: palette.text,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: palette.border),
                ),
              ),
              onPressed: onSearch,
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
}

class _HomeSection extends StatefulWidget {
  const _HomeSection({
    required this.title,
    required this.movies,
    required this.palette,
    required this.wishlistMap,
    required this.onWishlistToggle,
  });

  final String title;
  final AsyncValue<List<TmdbMovie>> movies;
  final _Palette palette;
  final Map<int, WishlistItem> wishlistMap;
  final ValueChanged<TmdbMovie> onWishlistToggle;

  @override
  State<_HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<_HomeSection> {
  final _controller = ScrollController();
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _offset = _controller.offset;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final min = _controller.position.minScrollExtent;
    final max = _controller.position.maxScrollExtent;
    final next = (_offset + delta).clamp(min, max);
    _controller.animateTo(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: widget.movies.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    '영화가 없습니다.',
                    style: TextStyle(color: palette.muted),
                  ),
                );
              }
              return Stack(
                children: [
                  ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    padding: const EdgeInsets.only(right: 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final m = items[index];
                      final picked = widget.wishlistMap.containsKey(m.id);
                      return _MovieCard(
                        movie: m,
                        palette: palette,
                        picked: picked,
                        onWishlistToggle: widget.onWishlistToggle,
                      );
                    },
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              palette.bg.withOpacity(0.7),
                              palette.bg.withOpacity(0.0),
                              palette.bg.withOpacity(0.0),
                              palette.bg.withOpacity(0.7),
                            ],
                            stops: const [0, 0.05, 0.95, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: _ArrowButton(
                      palette: palette,
                      icon: Icons.chevron_left,
                      onTap: () {
                        if (_controller.hasClients) {
                          _scrollBy(-180);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _ArrowButton(
                      palette: palette,
                      icon: Icons.chevron_right,
                      onTap: () {
                        if (_controller.hasClients) {
                          _scrollBy(180);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
            error: (e, _) => Center(
              child: Text(
                '불러오기 실패: $e',
                style: TextStyle(color: palette.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.palette,
    required this.icon,
    required this.onTap,
  });

  final _Palette palette;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: palette.card.withOpacity(0.9),
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: palette.text, size: 22),
          ),
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.movie,
    required this.palette,
    required this.picked,
    required this.onWishlistToggle,
  });

  final TmdbMovie movie;
  final _Palette palette;
  final bool picked;
  final ValueChanged<TmdbMovie> onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/movie/${movie.id}'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 210,
                  width: double.infinity,
                  color: palette.border,
                  child: movie.posterPath != null && movie.posterPath!.isNotEmpty
                      ? Image.network(
                          movie.posterUrl(),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            'No Image',
                            style: TextStyle(color: palette.muted),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => onWishlistToggle(movie),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: picked ? palette.accent : palette.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(
                        picked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: picked ? Colors.white : palette.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    movie.overview.isNotEmpty ? movie.overview : '줄거리가 없습니다.',
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
          ],
        ),
      ),
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
