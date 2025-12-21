import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/home/home_screen.dart';
import '../features/popular/popular_screen.dart';
import '../features/root/tab_shell.dart';
import '../features/search/search_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/wishlist/wishlist_screen.dart';
import '../features/movies/views/movie_detail_screen.dart';

/// Router provider to react to auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/movie/:id',
        name: 'movie',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(body: Center(child: Text('Invalid movie id')));
          }
          return MovieDetailScreen(id: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/popular',
                name: 'popular',
                builder: (context, state) => const PopularScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                name: 'wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/auth';
      final onSplash = state.matchedLocation == '/';

      if (authStatus == AuthStatus.unknown) {
        return onSplash ? null : '/';
      }

      if (authStatus == AuthStatus.signedOut && !loggingIn) {
        return '/auth';
      }

      if (authStatus == AuthStatus.signedIn && loggingIn) {
        return '/home';
      }

      return null;
    },
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(child: Text('Route error: ${state.error}')),
      );
    },
  );
});
