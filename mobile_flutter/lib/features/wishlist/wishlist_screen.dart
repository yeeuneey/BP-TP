import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../root/widgets/yeemin_app_bar.dart';
import 'data/wishlist_repository.dart';
import 'providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette =
        Theme.of(context).brightness == Brightness.dark ? _Palette.dark : _Palette.light;
    final wishlistAsync = ref.watch(wishlistStreamProvider);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const YeeminAppBar(),
      body: wishlistAsync.when(
        data: (items) {
          final wishlistMap = {
            for (final item in items) item.movieId: item,
          };

          if (items.isEmpty) {
            return _EmptyState(palette: palette);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '위시리스트',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '찜해 둔 영화들을 한 번에 모아봤어요.',
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 260,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final picked = wishlistMap.containsKey(item.movieId);
                    return _WishlistCard(
                      palette: palette,
                      item: item,
                      picked: picked,
                      onTap: () => context.go('/movie/${item.movieId}'),
                      onWishlistToggle: () =>
                          _toggleWishlist(context, ref, item, wishlistMap),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: palette.accent)),
        error: (e, _) => _ErrorState(
          palette: palette,
          message: '위시리스트를 불러오지 못했어요: $e',
        ),
      ),
    );
  }

  Future<void> _toggleWishlist(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
    Map<int, WishlistItem> wishlistMap,
  ) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final existing = wishlistMap[item.movieId];
    try {
      if (existing != null) {
        final confirmed = await _confirmRemoval(context);
        if (!confirmed) return;
        await repo.remove(existing.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('위시리스트에서 삭제했어요.')),
        );
      } else {
        await repo.add(item.movieId, item.title, item.posterUrl);
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

  Future<bool> _confirmRemoval(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('위시리스트에서 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.palette,
    required this.item,
    required this.picked,
    required this.onTap,
    required this.onWishlistToggle,
  });

  final _Palette palette;
  final WishlistItem item;
  final bool picked;
  final VoidCallback onTap;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
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
                      child: item.posterUrl.isNotEmpty
                          ? Image.network(
                              item.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _PosterPlaceholder(palette: palette),
                            )
                          : _PosterPlaceholder(palette: palette),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
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
                    '줄거리 정보가 없어요.',
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
                color: picked
                    ? palette.accent
                    : palette.card.withAlpha((0.95 * 255).round()),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, color: palette.accent, size: 36),
            const SizedBox(height: 10),
            Text(
              '위시리스트가 비어 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '마음에 드는 영화를 찜하고 이곳에서 한 번에 확인해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.palette, required this.message});

  final _Palette palette;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: palette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            ],
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
