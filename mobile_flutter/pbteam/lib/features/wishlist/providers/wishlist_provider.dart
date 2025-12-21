import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wishlist_repository.dart';

final wishlistStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(wishlistRepositoryProvider);
  return repo.watchWishlist();
});
