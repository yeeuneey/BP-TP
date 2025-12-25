import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';

class WishlistItem {
  WishlistItem({
    required this.id,
    required this.movieId,
    required this.title,
    required this.posterUrl,
    required this.createdAt,
  });

  final String id;
  final int movieId;
  final String title;
  final String posterUrl;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'title': title,
      'posterUrl': posterUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WishlistItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return WishlistItem(
      id: doc.id,
      movieId: data['movieId'] as int,
      title: data['title'] as String? ?? '',
      posterUrl: data['posterUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WishlistRepository {
  WishlistRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _colFor(String uid) =>
      _firestore.collection('wishlist').doc(uid).collection('items');

  Stream<List<WishlistItem>> watchWishlist() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _colFor(uid).orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(WishlistItem.fromDoc).toList(),
        );
  }

  Future<void> add(int movieId, String title, String posterUrl) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    await _colFor(uid).add(
      WishlistItem(
        id: '',
        movieId: movieId,
        title: title,
        posterUrl: posterUrl,
        createdAt: DateTime.now(),
      ).toJson(),
    );
  }

  Future<void> remove(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    await _colFor(uid).doc(id).delete();
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return WishlistRepository(firestore, auth);
});
