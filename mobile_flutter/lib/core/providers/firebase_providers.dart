import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ensures Firebase is initialized once and exposes core services.
final firebaseAppProvider = Provider<FirebaseApp>((ref) {
  // Already initialized in main(), but keeping for completeness if needed elsewhere.
  return Firebase.app();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  final app = ref.watch(firebaseAppProvider);
  return FirebaseAuth.instanceFor(app: app);
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final app = ref.watch(firebaseAppProvider);
  return FirebaseFirestore.instanceFor(app: app);
});
