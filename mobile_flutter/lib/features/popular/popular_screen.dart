import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../movies/models/tmdb_movie.dart';
import '../root/widgets/yeemin_app_bar.dart';
import '../wishlist/data/wishlist_repository.dart';
import '../wishlist/providers/wishlist_provider.dart';
import 'popular_controller.dart';

class PopularScreen extends ConsumerStatefulWidget {
  const PopularScreen({super.key});

  @override
  ConsumerState<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends ConsumerState<PopularScreen> {
  final _controller = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final state = ref.read(popularControllerProvider);
    if (_controller.hasClients &&
        state.hasMore &&
        !state.loading &&
        _controller.position.pixels > _controller.position.maxScrollExtent - 280) {
      ref.read(popularControllerProvider.notifier).loadMore();
    }
    final shouldShow = _controller.hasClients && _controller.offset > 420;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
  }

  Future<void> _toggleWishlist(TmdbMovie movie) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final wishlist = ref.read(wishlistStreamProvider).value ?? [];
    final messenger = ScaffoldMessenger.of(context);
    WishlistItem? existing;
    for (final item in wishlist) {
      if (item.movieId == movie.id) {
        existing = item;
        break;
      }
    }
    try {
      if (existing != null) {
        await repo.remove(existing.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에서 제거했어요.')),
        );
      } else {
        await repo.add(movie.id, movie.title, movie.posterUrl(size: 'w342'));
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에 추가했어요.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('요청에 실패했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).brightness == Brightness.dark ? _Palette.dark : _Palette.light;
    final state = ref.watch(popularControllerProvider);
    final wishlist = ref.watch(wishlistStreamProvider);
    final wishlistMap = {
      for (final item in wishlist.value ?? []) item.movieId: item,
    };
    final popularCtrl = ref.read(popularControllerProvider.notifier);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const YeeminAppBar(),
      body: state.initialLoading
          ? Center(child: CircularProgressIndicator(color: palette.accent))
          : RefreshIndicator(
              color: palette.accent,
              onRefresh: popularCtrl.refresh,
              child: ListView.builder(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: state.items.length + 1 + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _Header(
                      palette: palette,
                      error: state.items.isEmpty ? state.error : null,
                      onRetry: popularCtrl.loadInitial,
                    );
                  }
                  final itemIndex = index - 1;
                  if (itemIndex >= state.items.length) {
                    return _LoadMoreIndicator(
                      palette: palette,
                      loading: state.loading,
                      error: state.error,
                      onRetry: popularCtrl.loadMore,
                    );
                  }
                  final movie = state.items[itemIndex];
                  final picked = wishlistMap.containsKey(movie.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PopularCard(
                      palette: palette,
                      movie: movie,
                      picked: picked,
                      onTap: () => context.go('/movie/${movie.id}'),
                      onToggleWishlist: () => _toggleWishlist(movie),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _showScrollTop
          ? FloatingActionButton.small(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              onPressed: () {
                if (_controller.hasClients) {
                  _controller.animateTo(
                    0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    this.error,
    required this.onRetry,
  });

  final _Palette palette;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지금 가장 인기 있는 영화',
            style: TextStyle(
              color: palette.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'TMDB 실시간 인기 목록을 불러와요. 스크롤해서 더 보기!',
            style: TextStyle(
              color: palette.muted,
              fontSize: 13,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: palette.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '불러오는 중 문제가 생겼어요.',
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error!,
                          style: TextStyle(color: palette.muted, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                      side: BorderSide(color: palette.border),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({
    required this.palette,
    required this.movie,
    required this.picked,
    required this.onTap,
    required this.onToggleWishlist,
  });

  final _Palette palette;
  final TmdbMovie movie;
  final bool picked;
  final VoidCallback onTap;
  final VoidCallback onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    final ratingText =
        movie.voteAverage > 0 ? '★ ${movie.voteAverage.toStringAsFixed(1)}' : '★ 정보 없음';
    final releaseYear =
        (movie.releaseDate != null && movie.releaseDate!.length >= 4)
            ? '${movie.releaseDate!.substring(0, 4)}년'
            : '정보 없음';
    final runtimeText = movie.runtime != null ? '${movie.runtime}분' : '정보 없음';
    final countryText = movie.country ?? '정보 없음';
    final genreText = movie.genres.isNotEmpty ? movie.genres.join(', ') : '정보 없음';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Poster(palette: palette, movie: movie),
                  const SizedBox(width: 12),
                  Expanded(
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
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          movie.overview.isNotEmpty
                              ? movie.overview
                              : '줄거리가 등록되지 않았어요.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$ratingText · $releaseYear · $runtimeText',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$countryText · $genreText',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: picked ? palette.accent : palette.card,
                shape: const CircleBorder(),
                elevation: 5,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onToggleWishlist,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      picked ? Icons.favorite : Icons.favorite_border,
                      color: picked ? Colors.white : palette.text,
                      size: 18,
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

class _Poster extends StatelessWidget {
  const _Poster({required this.palette, required this.movie});

  final _Palette palette;
  final TmdbMovie movie;

  @override
  Widget build(BuildContext context) {
    final poster = movie.posterUrl(size: 'w342');
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        height: 150,
        color: palette.border,
        child: poster.isNotEmpty
            ? Image.network(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: palette.border,
      alignment: Alignment.center,
      child: Icon(Icons.hide_image_outlined, color: palette.muted),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator({
    required this.palette,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final _Palette palette;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (!loading && error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: palette.accent,
                      strokeWidth: 2.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '다음 페이지 로딩 중...',
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Text(
                    '로딩에 실패했어요. 다시 시도해 주세요.',
                    style: TextStyle(color: palette.muted),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                      side: BorderSide(color: palette.border),
                    ),
                    child: const Text('재시도'),
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
