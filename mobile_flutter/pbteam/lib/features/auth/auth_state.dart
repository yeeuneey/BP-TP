import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/providers/firebase_providers.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthStateNotifier extends Notifier<AuthStatus> {
  late final FirebaseAuth _auth;
  StreamSubscription<User?>? _sub;

  @override
  AuthStatus build() {
    _auth = ref.read(firebaseAuthProvider);
    _sub = _auth.authStateChanges().listen((user) {
      state = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    });
    ref.onDispose(() {
      _sub?.cancel();
    });
    return AuthStatus.unknown;
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }
}

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthStatus>(AuthStateNotifier.new);
