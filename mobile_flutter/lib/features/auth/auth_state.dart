import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/providers/firebase_providers.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthStateNotifier extends Notifier<AuthStatus> {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;
  late final Future<void> _googleInit;
  StreamSubscription<User?>? _sub;

  @override
  AuthStatus build() {
    _auth = ref.read(firebaseAuthProvider);
    _googleSignIn = GoogleSignIn.instance;
    _googleInit = _googleSignIn.initialize();
    _sub = _auth.authStateChanges().listen((user) {
      state = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    });
    ref.onDispose(() {
      _sub?.cancel();
    });
    return AuthStatus.unknown;
  }

  Future<void> signOut() async {
    await _googleInit;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    await _googleInit;
    GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw StateError('Google sign-in was cancelled');
      }
      rethrow;
    }
    final googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw StateError(
        'Google sign-in did not return an ID token. '
        'Check the Google client configuration in firebase/google-services.json.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthStatus>(
  AuthStateNotifier.new,
);
