import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await _initFirebase();
  runApp(const AppRoot());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(options: _firebaseOptionsFromEnv());
  } on FirebaseException catch (e) {
    // Hot restart 시 이미 초기화된 경우 duplicate-app 오류를 무시하고 계속 진행.
    if (e.code != 'duplicate-app') rethrow;
  }
}

FirebaseOptions _firebaseOptionsFromEnv() {
  String requireEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing env: $key');
    }
    return value;
  }

  return FirebaseOptions(
    apiKey: requireEnv('FIREBASE_API_KEY'),
    appId: requireEnv('FIREBASE_APP_ID'),
    messagingSenderId: requireEnv('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: requireEnv('FIREBASE_PROJECT_ID'),
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
  );
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontScale = 1.0;
  bool _reduceMotion = false;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _adjustFontScale(double delta) {
    setState(() {
      final next = (_fontScale + delta).clamp(0.9, 1.2);
      _fontScale = next.toDouble();
    });
  }

  void _toggleReduceMotion() {
    setState(() {
      _reduceMotion = !_reduceMotion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageTransitions = _reduceMotion
        ? PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          )
        : const PageTransitionsTheme();

    return MaterialApp(
      title: 'YEEMIN',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE50914)),
        pageTransitionsTheme: pageTransitions,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE50914),
          brightness: Brightness.dark,
          background: Colors.black,
          surface: Colors.black,
        ),
        pageTransitionsTheme: pageTransitions,
        useMaterial3: true,
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaleFactor: _fontScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(
        onToggleTheme: _toggleTheme,
        onFontScaleUp: () => _adjustFontScale(0.05),
        onFontScaleDown: () => _adjustFontScale(-0.05),
        onToggleReduceMotion: _toggleReduceMotion,
        themeMode: _themeMode,
        reduceMotion: _reduceMotion,
      ),
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.onToggleTheme,
    required this.onFontScaleUp,
    required this.onFontScaleDown,
    required this.onToggleReduceMotion,
    required this.themeMode,
    required this.reduceMotion,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback onFontScaleUp;
  final VoidCallback onFontScaleDown;
  final VoidCallback onToggleReduceMotion;
  final ThemeMode themeMode;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const AuthScreen();
        }

        return MainScreen(
          onToggleTheme: onToggleTheme,
          onFontScaleUp: onFontScaleUp,
          onFontScaleDown: onFontScaleDown,
          onToggleReduceMotion: onToggleReduceMotion,
          themeMode: themeMode,
          reduceMotion: reduceMotion,
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _busy = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter email and password.');
      return;
    }

    if (!_isLogin && password != confirm) {
      _showMessage('Password confirmation does not match.');
      return;
    }

    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _showMessage('Account created. You can sign in now.');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Auth failed.');
    } catch (e) {
      _showMessage('Auth failed: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _busy = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Google login failed.');
    } catch (e) {
      _showMessage('Google login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo-yeemin.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'YEEMIN',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFE50914),
                            letterSpacing: 0.12,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('LOGIN')),
                    ButtonSegment(value: false, label: Text('SIGN UP')),
                  ],
                  selected: {_isLogin},
                  onSelectionChanged: (selection) {
                    setState(() => _isLogin = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _handleEmailAuth,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Sign in with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.onFontScaleUp,
    required this.onFontScaleDown,
    required this.onToggleReduceMotion,
    required this.themeMode,
    required this.reduceMotion,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback onFontScaleUp;
  final VoidCallback onFontScaleDown;
  final VoidCallback onToggleReduceMotion;
  final ThemeMode themeMode;
  final bool reduceMotion;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  bool _loadingMovies = false;
  bool _loadingPopular = false;
  bool _loadingSearch = false;
  bool _hasMorePopular = true;
  int _popularPage = 1;
  String _searchQuery = '';
  List<Movie> _searchSuggestions = [];
  List<String> _recentSearches = [];
  List<Movie> _searchResultsRaw = [];
  Map<int, String> _genres = {};
  int? _selectedGenreId;
  String? _selectedYear;
  double _minRating = 0;
  String _sortOption = 'popularity';
  List<Movie> _nowPlaying = [];
  List<Movie> _popular = [];
  List<Movie> _searchResults = [];
  List<WishlistItem> _wishlist = [];
  List<TrailerInfo> _heroPlaylist = [];
  int _heroIndex = 0;
  bool _heroLoading = false;
  String? _heroError;
  Timer? _suggestionDebounce;
  Timer? _heroAutoTimer;

  // Fallback trailers known to allow embedding (demo-safe).
  static final List<TrailerInfo> _fallbackTrailers = [
  TrailerInfo(
    movie: Movie(
      id: -1,
      title: 'Big Buck Bunny',
      overview: 'Open movie project trailer (embed-friendly).',
      posterPath: null,
      backdropPath: null,
    ),
    videoKey: 'aqz-KE-bpKQ',
    name: 'Big Buck Bunny Trailer',
  ),
  TrailerInfo(
    movie: Movie(
      id: -2,
      title: 'Sintel',
      overview: 'Blender open movie trailer (embed-friendly).',
      posterPath: null,
      backdropPath: null,
    ),
    videoKey: 'eRsGyueVLvQ',
    name: 'Sintel Trailer',
  ),
];

  late final TmdbApi _tmdb;

  @override
  void initState() {
    super.initState();
    _tmdb = TmdbApi(dotenv.env['TMDB_API_KEY'] ?? '');
    _loadInitial();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _heroAutoTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadMovies(),
      _loadWishlist(),
      _loadGenres(),
    ]);
    _startHeroAutoAdvance();
  }

  Future<void> _loadMovies() async {
    if (_tmdb.apiKey.isEmpty) {
      _showMessage('Missing TMDB API key.');
      return;
    }
    setState(() => _loadingMovies = true);
    try {
      final nowPlaying = await _tmdb.nowPlaying();
      final popular = await _tmdb.popular(1);
      if (!mounted) return;
      setState(() {
        _nowPlaying = nowPlaying.take(10).toList();
        _popular = popular;
        _popularPage = 1;
        _hasMorePopular = popular.isNotEmpty;
        if (_searchQuery.isEmpty) {
          final base = _collectBaseMovies();
          _searchResultsRaw = base;
          _searchResults = _applySearchFilters(base);
        }
      });
      await _loadHeroPlaylist();
    } catch (e) {
      _showMessage('Failed to load movies: $e');
    } finally {
      if (mounted) setState(() => _loadingMovies = false);
    }
  }

  Future<void> _loadGenres() async {
    if (_tmdb.apiKey.isEmpty) return;
    try {
      final genres = await _tmdb.genres();
      if (!mounted) return;
      setState(() => _genres = genres);
    } catch (_) {
      // best-effort: ignore genre load errors
    }
  }

  Future<void> _loadPopularMore() async {
    if (_loadingPopular || !_hasMorePopular) return;
    setState(() => _loadingPopular = true);
    try {
      final nextPage = _popularPage + 1;
      final items = await _tmdb.popular(nextPage);
      if (!mounted) return;
      setState(() {
        final merged = {...{for (var m in _popular) m.id: m}, for (var m in items) m.id: m};
        _popular = merged.values.toList();
        _popularPage = nextPage;
        _hasMorePopular = items.isNotEmpty;
      });
    } catch (e) {
      _showMessage('Failed to load more: $e');
    } finally {
      if (mounted) setState(() => _loadingPopular = false);
    }
  }

  Future<void> _loadHeroPlaylist() async {
    final candidates = [
      ..._popular,
      ..._nowPlaying,
    ];
    if (candidates.isEmpty) {
      setState(() {
        _heroPlaylist = [];
        _heroError = '트레일러를 보여줄 영화가 없습니다.';
      });
      return;
    }

    setState(() {
      _heroLoading = true;
      _heroError = null;
      _heroPlaylist = [];
      _heroIndex = 0;
    });

    final seen = <int>{};
    final List<TrailerInfo> playlist = [];
    for (final movie in candidates) {
      if (seen.contains(movie.id)) continue;
      seen.add(movie.id);
      try {
        final video = await _tmdb.trailer(movie.id);
        if (video != null && video.key.isNotEmpty) {
          playlist.add(
            TrailerInfo(movie: movie, videoKey: video.key, name: video.name),
          );
        }
      } catch (_) {
        // ignore individual failures
      }
      if (playlist.length >= 5) break;
    }

    if (!mounted) return;
    setState(() {
      _heroPlaylist = playlist;
      _heroError = playlist.isEmpty ? '예고편을 찾을 수 없어요.' : null;
      _heroIndex = 0;
    });
    _startHeroAutoAdvance();
    if (mounted) setState(() => _heroLoading = false);
  }

  void _nextHero() {
    if (_heroPlaylist.length <= 1) return;
    setState(() {
      _heroIndex = (_heroIndex + 1) % _heroPlaylist.length;
    });
    _startHeroAutoAdvance();
  }

  void _setHeroIndex(int index) {
    if (index < 0 || index >= _heroPlaylist.length) return;
    setState(() {
      _heroIndex = index;
    });
    _startHeroAutoAdvance();
  }

  void _startHeroAutoAdvance() {
    _heroAutoTimer?.cancel();
    if (_heroPlaylist.length <= 1) return;
    _heroAutoTimer = Timer(const Duration(seconds: 10), _nextHero);
  }

  Future<void> _loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('wishlists').doc(user.uid).get();
      final items = (doc.data()?['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WishlistItem.fromMap)
          .toList();
      if (!mounted) return;
      setState(() => _wishlist = items);
    } catch (e) {
      _showMessage('Failed to load wishlist: $e');
    }
  }

  Future<void> _toggleWishlist(Movie movie) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

    final exists = _wishlist.any((w) => w.id == movie.id);
    final next = exists
        ? _wishlist.where((w) => w.id != movie.id).toList()
        : [..._wishlist, WishlistItem(id: movie.id, title: movie.title, posterPath: movie.posterPath)];

    setState(() => _wishlist = next);

    try {
      await FirebaseFirestore.instance.collection('wishlists').doc(user.uid).set(
        {'items': next.map((w) => w.toMap()).toList()},
        SetOptions(merge: true),
      );
    } catch (e) {
      _showMessage('Failed to update wishlist: $e');
    }
  }

  Future<void> _showMovieDetails(Movie movie) async {
    if (_tmdb.apiKey.isEmpty) {
      _showMessage('Missing TMDB API key.');
      return;
    }
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: true,
      builder: (context) {
        return FutureBuilder<MovieDetail>(
          future: _tmdb.movieDetail(movie.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('세부 정보를 불러오지 못했습니다: ${snapshot.error}'),
              );
            }
            final detail = snapshot.data ?? MovieDetail.fromMovie(movie);
            final wishlisted = _wishlist.any((w) => w.id == detail.id);
            final imageUrl = detail.backdropUrl ?? detail.posterUrl;
            final directorText = detail.directors.isNotEmpty ? detail.directors.join(', ') : '정보 없음';
            final castNames = detail.cast.take(6).map((c) => c.name).where((n) => n.isNotEmpty).toList();
            final runtimeText = detail.runtime != null ? '${detail.runtime}분' : '정보 없음';
            final releaseYear =
                (detail.releaseDate != null && detail.releaseDate!.isNotEmpty) ? detail.releaseDate!.split('-').first : '정보 없음';

            return StatefulBuilder(
              builder: (context, setSheetState) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        detail.title,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(detail.voteAverage?.toStringAsFixed(1) ?? 'NR'),
                            ],
                          ),
                          Text('러닝타임: $runtimeText'),
                          Text('개봉년도: $releaseYear'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (detail.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: detail.genres.map((g) => Chip(label: Text(g))).toList(),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        detail.overview.isNotEmpty ? detail.overview : 'No overview available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('감독: $directorText', style: theme.textTheme.bodyMedium),
                      if (castNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('주요 출연: ${castNames.join(', ')}', style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              await _toggleWishlist(detail);
                              if (context.mounted) setSheetState(() {});
                            },
                            icon: Icon(wishlisted ? Icons.favorite : Icons.favorite_border),
                            label: Text(wishlisted ? '위시리스트 제거' : '위시리스트 추가'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final url = Uri.parse('https://www.themoviedb.org/movie/${detail.id}');
                              launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('TMDB에서 보기'),
                          ),
                          OutlinedButton.icon(
                            onPressed: Navigator.of(context).maybePop,
                            icon: const Icon(Icons.close),
                            label: const Text('닫기'),
                          ),
                        ],
                      ),
                      if (detail.similar.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('비슷한 작품', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: detail.similar.take(12).map((m) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _showMovieDetails(m);
                                    });
                                  },
                                  child: SizedBox(
                                    width: 120,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 2 / 3,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: m.posterUrl != null
                                                ? Image.network(m.posterUrl!, fit: BoxFit.cover)
                                                : Container(
                                                    color: Colors.black12,
                                                    child: const Center(child: Text('No Image')),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          m.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleSearch() async {
    final query = _searchQuery.trim();
    if (query.isEmpty) {
      final base = _collectBaseMovies();
      setState(() {
        _searchResultsRaw = base;
        _searchResults = _applySearchFilters(base);
        _searchSuggestions = [];
        _tabIndex = 2;
      });
      return;
    }

    if (_tmdb.apiKey.isEmpty) {
      _showMessage('Missing TMDB API key.');
      return;
    }

    setState(() => _loadingSearch = true);
    try {
      final results = await _tmdb.search(query);
      if (!mounted) return;
      final filtered = _applySearchFilters(results);
      setState(() {
        _searchResultsRaw = results;
        _searchResults = filtered;
        _searchSuggestions = [];
        _tabIndex = 2;
      });
      _addRecentSearch(query);
    } catch (e) {
      _showMessage('Search failed: $e');
    } finally {
      if (mounted) setState(() => _loadingSearch = false);
    }
  }

  void _onSearchQueryChanged(String value) {
    setState(() => _searchQuery = value);
    _suggestionDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() => _searchSuggestions = []);
      return;
    }
    _suggestionDebounce = Timer(const Duration(milliseconds: 350), () => _loadSuggestions(trimmed));
  }

  Future<void> _loadSuggestions(String query) async {
    if (_tmdb.apiKey.isEmpty) return;
    try {
      final results = await _tmdb.search(query);
      if (!mounted) return;
      setState(() => _searchSuggestions = results.take(6).toList());
    } catch (_) {
      // ignore suggestion errors
    }
  }

  void _addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final next = [trimmed, ..._recentSearches.where((q) => q.toLowerCase() != trimmed.toLowerCase())];
    setState(() => _recentSearches = next.take(6).toList());
  }

  List<Movie> _applySearchFilters(List<Movie> results) {
    final filtered = results.where((movie) {
      if (_selectedGenreId != null && _selectedGenreId != 0 && !movie.genreIds.contains(_selectedGenreId)) {
        return false;
      }
      if (_selectedYear != null && _selectedYear!.isNotEmpty) {
        final year = (movie.releaseDate ?? '').split('-').first;
        if (year != _selectedYear) return false;
      }
      if (_minRating > 0 && (movie.voteAverage ?? 0) < _minRating) {
        return false;
      }
      return true;
    }).toList();

    int compareDate(Movie a, Movie b) {
      DateTime? parse(String? value) {
        if (value == null || value.isEmpty) return null;
        try {
          return DateTime.tryParse(value);
        } catch (_) {
          return null;
        }
      }

      final da = parse(a.releaseDate);
      final db = parse(b.releaseDate);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    }

    switch (_sortOption) {
      case 'rating':
        filtered.sort((a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0));
        break;
      case 'newest':
        filtered.sort(compareDate);
        break;
      case 'popularity':
      default:
        filtered.sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
    }
    return filtered;
  }

  List<Movie> _collectBaseMovies() {
    final merged = {
      for (final m in [..._popular, ..._nowPlaying]) m.id: m,
    };
    return merged.values.toList();
  }

  void _applyFiltersFromBase() {
    final hasQuery = _searchQuery.trim().isNotEmpty;
    final List<Movie> base = hasQuery
        ? _searchResultsRaw
        : _collectBaseMovies();
    setState(() {
      _searchResultsRaw = base;
      _searchResults = _applySearchFilters(base);
      _tabIndex = 2;
    });
  }

  void _setGenre(int? genreId) {
    setState(() {
      _selectedGenreId = genreId;
    });
    _applyFiltersFromBase();
  }

  void _setYear(String? year) {
    setState(() {
      _selectedYear = year;
    });
    _applyFiltersFromBase();
  }

  void _setMinRating(double rating) {
    setState(() {
      _minRating = rating;
    });
    _applyFiltersFromBase();
  }

  void _setSortOption(String option) {
    setState(() {
      _sortOption = option;
    });
    _applyFiltersFromBase();
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
        nowPlaying: _nowPlaying,
        popular: _popular,
        wishlist: _wishlist,
        loading: _loadingMovies,
        playlist: _heroPlaylist,
        currentTrailerIndex: _heroIndex,
        loadingTrailer: _heroLoading,
        trailerError: _heroError,
        onNextTrailer: _nextHero,
        onSetTrailerIndex: _setHeroIndex,
        onToggleWishlist: _toggleWishlist,
        onOpenDetails: _showMovieDetails,
      ),
      _PopularTab(
        popular: _popular,
        wishlist: _wishlist,
        loading: _loadingPopular,
        hasMore: _hasMorePopular,
        onLoadMore: _loadPopularMore,
        onToggleWishlist: _toggleWishlist,
        onOpenDetails: _showMovieDetails,
      ),
      _SearchTab(
        results: _searchResults,
        wishlist: _wishlist,
        loading: _loadingSearch,
        searchQuery: _searchQuery,
        suggestions: _searchSuggestions,
        recentSearches: _recentSearches,
        genreOptions: _genres,
        selectedGenreId: _selectedGenreId,
        selectedYear: _selectedYear,
        minRating: _minRating,
        sortOption: _sortOption,
        onSearchQueryChanged: _onSearchQueryChanged,
        onSearch: _handleSearch,
        onToggleWishlist: _toggleWishlist,
        onSuggestionTap: (value) {
          _onSearchQueryChanged(value);
          _handleSearch();
        },
        onRecentTap: (value) {
          _onSearchQueryChanged(value);
          _handleSearch();
        },
        onSelectGenre: _setGenre,
        onSelectYear: _setYear,
        onRatingChanged: _setMinRating,
        onSortChanged: _setSortOption,
        onOpenDetails: _showMovieDetails,
      ),
      _WishlistTab(
        wishlist: _wishlist,
        onToggleWishlist: _toggleWishlist,
        onOpenDetails: _showMovieDetails,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo-yeemin.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'YEEMIN',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.12,
                color: Color(0xFFE50914),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              switch (action) {
                case _MenuAction.theme:
                  widget.onToggleTheme();
                  break;
                case _MenuAction.fontUp:
                  widget.onFontScaleUp();
                  break;
                case _MenuAction.fontDown:
                  widget.onFontScaleDown();
                  break;
                case _MenuAction.motion:
                  widget.onToggleReduceMotion();
                  break;
                case _MenuAction.logout:
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.theme,
                child: Text('Theme: ${widget.themeMode == ThemeMode.dark ? 'Dark' : 'Light'}'),
              ),
              const PopupMenuItem(
                value: _MenuAction.fontUp,
                child: Text('Font bigger'),
              ),
              const PopupMenuItem(
                value: _MenuAction.fontDown,
                child: Text('Font smaller'),
              ),
              PopupMenuItem(
                value: _MenuAction.motion,
                child: Text('Animations: ${widget.reduceMotion ? 'Off' : 'On'}'),
              ),
              const PopupMenuItem(
                value: _MenuAction.logout,
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.local_fire_department), label: 'Popular'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Wishlist'),
        ],
      ),
    );
  }
}

enum _MenuAction { theme, fontUp, fontDown, motion, logout }

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.nowPlaying,
    required this.popular,
    required this.wishlist,
    required this.loading,
    required this.playlist,
    required this.currentTrailerIndex,
    required this.loadingTrailer,
    required this.trailerError,
    required this.onNextTrailer,
    required this.onSetTrailerIndex,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final List<Movie> nowPlaying;
  final List<Movie> popular;
  final List<WishlistItem> wishlist;
  final bool loading;
  final List<TrailerInfo> playlist;
  final int currentTrailerIndex;
  final bool loadingTrailer;
  final String? trailerError;
  final VoidCallback onNextTrailer;
  final ValueChanged<int> onSetTrailerIndex;
  final ValueChanged<Movie> onToggleWishlist;
  final ValueChanged<Movie> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (playlist.isNotEmpty || loadingTrailer || (trailerError != null && trailerError!.isNotEmpty)) ...[
          _TrailerBanner(
            playlist: playlist,
            currentIndex: currentTrailerIndex,
            onNext: onNextTrailer,
            onSetIndex: onSetTrailerIndex,
            loading: loadingTrailer,
            error: trailerError,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'TMDB picks for you',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Trending movies, top titles, and upcoming gems.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (loading) const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 16),
        _MovieSection(
          title: 'Popular now',
          movies: popular,
          wishlist: wishlist,
          onToggleWishlist: onToggleWishlist,
          onOpenDetails: onOpenDetails,
        ),
        const SizedBox(height: 16),
        _MovieSection(
          title: 'Now playing',
          movies: nowPlaying,
          wishlist: wishlist,
          onToggleWishlist: onToggleWishlist,
          onOpenDetails: onOpenDetails,
        ),
      ],
    );
  }
}


class _TrailerBanner extends StatelessWidget {
  const _TrailerBanner({
    required this.playlist,
    required this.currentIndex,
    required this.onNext,
    required this.onSetIndex,
    required this.loading,
    required this.error,
  });

  final List<TrailerInfo> playlist;
  final int currentIndex;
  final VoidCallback onNext;
  final ValueChanged<int> onSetIndex;
  final bool loading;
  final String? error;

  Future<void> _openInYoutube(BuildContext context, String videoKey) async {
    if (videoKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 트레일러가 없어요.')),
      );
      return;
    }
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoKey');
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('YouTube를 열 수 없어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _BannerShell(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && error!.isNotEmpty) {
      return _BannerShell(
        child: Text(
          error!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      );
    }
    if (playlist.isEmpty || currentIndex >= playlist.length) {
      return const SizedBox.shrink();
    }
    final trailer = playlist[currentIndex];

    final imageUrl = trailer.backdropUrl ?? trailer.movie.posterUrl;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _BannerShell(
        key: ValueKey(trailer.videoKey),
        imageUrl: imageUrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exclusive Trailer',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              trailer.movie.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              trailer.movie.overview.isNotEmpty
                  ? trailer.movie.overview
                  : 'No overview available.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next trailer'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openInYoutube(context, trailer.videoKey),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Watch on YouTube'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                ),
              ],
            ),
            if (playlist.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  playlist.length,
                  (idx) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSetIndex(idx),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: idx == currentIndex ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({Key? key, this.imageUrl, required this.child}) : super(key: key);

  final String? imageUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 360, maxHeight: 520),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          image: imageUrl == null
              ? null
              : DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularTab extends StatelessWidget {
  const _PopularTab({
    required this.popular,
    required this.wishlist,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final List<Movie> popular;
  final List<WishlistItem> wishlist;
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<Movie> onToggleWishlist;
  final ValueChanged<Movie> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Popular movies',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...popular.map(
          (movie) => _MovieRow(
            movie: movie,
            isWishlisted: wishlist.any((w) => w.id == movie.id),
            onToggleWishlist: () => onToggleWishlist(movie),
            onOpenDetails: () => onOpenDetails(movie),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: OutlinedButton(
              onPressed: loading ? null : onLoadMore,
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
                  : const Text('Load more'),
            ),
          ),
      ],
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.results,
    required this.wishlist,
    required this.loading,
    required this.searchQuery,
    required this.suggestions,
    required this.recentSearches,
    required this.genreOptions,
    required this.selectedGenreId,
    required this.selectedYear,
    required this.minRating,
    required this.sortOption,
    required this.onSearchQueryChanged,
    required this.onSearch,
    required this.onToggleWishlist,
    required this.onSuggestionTap,
    required this.onRecentTap,
    required this.onSelectGenre,
    required this.onSelectYear,
    required this.onRatingChanged,
    required this.onSortChanged,
    required this.onOpenDetails,
  });

  final List<Movie> results;
  final List<WishlistItem> wishlist;
  final bool loading;
  final String searchQuery;
  final List<Movie> suggestions;
  final List<String> recentSearches;
  final Map<int, String> genreOptions;
  final int? selectedGenreId;
  final String? selectedYear;
  final double minRating;
  final String sortOption;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSearch;
  final ValueChanged<Movie> onToggleWishlist;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<int?> onSelectGenre;
  final ValueChanged<String?> onSelectYear;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<Movie> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final years = List<String>.generate(15, (i) => '${DateTime.now().year - i}');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Search',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _SearchRow(
          value: searchQuery,
          onChanged: onSearchQueryChanged,
          onSearch: onSearch,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('자동완성', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          ...suggestions.map(
            (movie) => ListTile(
              dense: true,
              title: Text(movie.title),
              subtitle: movie.releaseDate != null ? Text(movie.releaseDate!) : null,
              onTap: () => onSuggestionTap(movie.title),
            ),
          ),
        ],
        if (recentSearches.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('최근 검색어', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches
                .map((q) => ActionChip(label: Text(q), onPressed: () => onRecentTap(q)))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('필터 & 정렬', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<int?>(
                        value: selectedGenreId,
                        decoration: const InputDecoration(labelText: '장르'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('전체')),
                          ...genreOptions.entries.map(
                            (e) => DropdownMenuItem<int?>(value: e.key, child: Text(e.value)),
                          ),
                        ],
                        onChanged: onSelectGenre,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String?>(
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: '년도'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('전체')),
                          ...years.map((y) => DropdownMenuItem<String?>(value: y, child: Text(y))),
                        ],
                        onChanged: onSelectYear,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: sortOption,
                        decoration: const InputDecoration(labelText: '정렬'),
                        items: const [
                          DropdownMenuItem(value: 'popularity', child: Text('인기순')),
                          DropdownMenuItem(value: 'rating', child: Text('평점순')),
                          DropdownMenuItem(value: 'newest', child: Text('최신순')),
                        ],
                        onChanged: (value) {
                          if (value != null) onSortChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('최소 평점: ${minRating.toStringAsFixed(1)}'),
                Slider(
                  value: minRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: minRating.toStringAsFixed(1),
                  onChanged: onRatingChanged,
                ),
              ],
            ),
          ),
        ),
        if (loading) const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 8),
        ...results.map(
          (movie) => _MovieRow(
            movie: movie,
            isWishlisted: wishlist.any((w) => w.id == movie.id),
            onToggleWishlist: () => onToggleWishlist(movie),
            onOpenDetails: () => onOpenDetails(movie),
          ),
        ),
      ],
    );
  }
}

class _WishlistTab extends StatelessWidget {
  const _WishlistTab({
    required this.wishlist,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final List<WishlistItem> wishlist;
  final ValueChanged<Movie> onToggleWishlist;
  final ValueChanged<Movie> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Wishlist',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (wishlist.isEmpty)
          Text(
            'Your wishlist is empty.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ...wishlist.map(
          (item) => _MovieRow(
            movie: Movie(
              id: item.id,
              title: item.title,
              overview: '',
              posterPath: item.posterPath,
              backdropPath: null,
            ),
            isWishlisted: true,
            onToggleWishlist: () => onToggleWishlist(
              Movie(
                id: item.id,
                title: item.title,
                overview: '',
                posterPath: item.posterPath,
                backdropPath: null,
              ),
            ),
            onOpenDetails: () => onOpenDetails(
              Movie(
                id: item.id,
                title: item.title,
                overview: '',
                posterPath: item.posterPath,
                backdropPath: null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.value,
    required this.onChanged,
    required this.onSearch,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search movies',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSearch(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }
}

class _MovieSection extends StatelessWidget {
  const _MovieSection({
    required this.title,
    required this.movies,
    required this.wishlist,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final String title;
  final List<Movie> movies;
  final List<WishlistItem> wishlist;
  final ValueChanged<Movie> onToggleWishlist;
  final ValueChanged<Movie> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = movies[index];
              final isWishlisted = wishlist.any((w) => w.id == movie.id);
              return _MovieCard(
                movie: movie,
                isWishlisted: isWishlisted,
                onToggleWishlist: () => onToggleWishlist(movie),
                onOpenDetails: () => onOpenDetails(movie),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.movie,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final Movie movie;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: movie.posterUrl != null
                          ? Image.network(movie.posterUrl!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.black12,
                              child: const Center(child: Text('No Image')),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
                        onPressed: onToggleWishlist,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({
    required this.movie,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final Movie movie;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 120,
                child: movie.posterUrl != null
                    ? Image.network(movie.posterUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.black12,
                        child: const Center(child: Text('No Image')),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.overview.isNotEmpty ? movie.overview : 'No overview available.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
                onPressed: onToggleWishlist,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TmdbApi {
  TmdbApi(this.apiKey, {this.language = 'ko-KR'});

  final String apiKey;
  final String language;

  static const _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> nowPlaying() async {
    return _getMovies('/movie/now_playing', {'region': 'KR'});
  }

  Future<List<Movie>> popular(int page) async {
    return _getMovies('/movie/popular', {'page': '$page'});
  }

  Future<List<Movie>> search(String query) async {
    return _getMovies('/search/movie', {'query': query});
  }

  Future<MovieDetail> movieDetail(int movieId) async {
    final data = await _getJson('/movie/$movieId', {'append_to_response': 'credits,similar'});
    return MovieDetail.fromTmdb(data);
  }

  Future<Map<int, String>> genres() async {
    final data = await _getJson('/genre/movie/list', {});
    final list = (data['genres'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((g) => g['id'] != null && g['name'] != null)
        .map((g) => MapEntry(g['id'] as int, g['name'] as String))
        .toList();
    return {for (final entry in list) entry.key: entry.value};
  }

  Future<TmdbVideo?> trailer(int movieId) async {
    final fetched = await videos(movieId);
    // 우선순위: 공식 + 트레일러/티저 + 언어 en/ko -> 공식 기타 -> 나머지
    final preferredLang = fetched.where(
      (v) => _isPlayable(v, officialOnly: true) && _isPreferredLang(v),
    );
    final official = fetched.where((v) => _isPlayable(v, officialOnly: true));
    final fallback = fetched.where((v) => _isPlayable(v, officialOnly: false));
    final sorted = [
      ...preferredLang,
      ...official,
      ...fallback,
    ];
    return sorted.isNotEmpty ? sorted.first : null;
  }

  Future<List<TmdbVideo>> videos(int movieId) async {
    final data = await _getJson('/movie/$movieId/videos', {'include_video_language': language});
    final results = (data['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TmdbVideo.fromTmdb)
        .toList();
    return results;
  }

  Future<List<Movie>> _getMovies(String path, Map<String, String> params) async {
    final data = await _getJson(path, params);
    final results = (data['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromTmdb)
        .toList();
    return results;
  }

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> params) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: {
        'api_key': apiKey,
        'language': language,
        ...params,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw StateError('TMDB error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data;
  }
}

bool _isPlayable(TmdbVideo video, {required bool officialOnly}) {
  final isYoutube = video.site.toLowerCase() == 'youtube';
  final isTrailer = video.type.toLowerCase() == 'trailer' || video.type.toLowerCase() == 'teaser';
  final officialOk = !officialOnly || video.official;
  return isYoutube && isTrailer && officialOk && video.key.isNotEmpty;
}

bool _isPreferredLang(TmdbVideo video) {
  final lang = video.language.toLowerCase();
  return lang == 'en' || lang == 'ko' || lang.isEmpty;
}

class Movie {
  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    this.voteAverage,
    this.releaseDate,
    this.runtime,
    this.genres = const [],
    this.genreIds = const [],
    this.popularity,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseDate;
  final int? runtime;
  final List<String> genres;
  final List<int> genreIds;
  final double? popularity;

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w342$posterPath';
  String? get backdropUrl =>
      backdropPath == null ? null : 'https://image.tmdb.org/t/p/w780$backdropPath';

  factory Movie.fromTmdb(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      overview: (json['overview'] as String?) ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      releaseDate: json['release_date'] as String?,
      runtime: json['runtime'] as int?,
      genres: (json['genres'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((g) => g['name'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList() ??
          const [],
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.whereType<int>()
              .toList() ??
          const [],
      popularity: (json['popularity'] as num?)?.toDouble(),
    );
  }
}

class MovieDetail extends Movie {
  MovieDetail({
    required super.id,
    required super.title,
    required super.overview,
    required super.posterPath,
    required super.backdropPath,
    super.voteAverage,
    super.releaseDate,
    super.runtime,
    super.genres = const [],
    super.genreIds = const [],
    super.popularity,
    this.cast = const [],
    this.directors = const [],
    this.similar = const [],
  });

  final List<Credit> cast;
  final List<String> directors;
  final List<Movie> similar;

  static MovieDetail fromMovie(Movie movie) {
    return MovieDetail(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
      runtime: movie.runtime,
      genres: movie.genres,
      genreIds: movie.genreIds,
      popularity: movie.popularity,
    );
  }

  factory MovieDetail.fromTmdb(Map<String, dynamic> json) {
    final base = Movie.fromTmdb(json);
    final credits = (json['credits'] as Map<String, dynamic>?) ?? {};
    final cast = (credits['cast'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Credit.fromCast)
        .toList();
    final directors = (credits['crew'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((c) => (c['job'] as String?)?.toLowerCase() == 'director')
        .map((c) => (c['name'] as String?) ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final similar = (json['similar'] as Map<String, dynamic>? ?? {})['results'] as List<dynamic>? ?? [];
    return MovieDetail(
      id: base.id,
      title: base.title,
      overview: base.overview,
      posterPath: base.posterPath,
      backdropPath: base.backdropPath,
      voteAverage: base.voteAverage,
      releaseDate: base.releaseDate,
      runtime: base.runtime,
      genres: base.genres,
      genreIds: base.genreIds,
      popularity: base.popularity,
      cast: cast,
      directors: directors,
      similar: similar.whereType<Map<String, dynamic>>().map(Movie.fromTmdb).toList(),
    );
  }
}

class Credit {
  Credit({required this.name, required this.role});

  final String name;
  final String role;

  factory Credit.fromCast(Map<String, dynamic> json) {
    return Credit(
      name: (json['name'] as String?) ?? '',
      role: (json['character'] as String?) ?? '',
    );
  }
}

class TmdbVideo {
  TmdbVideo({
    required this.key,
    required this.site,
    required this.type,
    required this.name,
    required this.official,
    required this.language,
    required this.country,
  });

  final String key;
  final String site;
  final String type;
  final String name;
  final bool official;
  final String language;
  final String country;

  factory TmdbVideo.fromTmdb(Map<String, dynamic> json) {
    return TmdbVideo(
      key: (json['key'] as String?) ?? '',
      site: (json['site'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      official: (json['official'] as bool?) ?? false,
      language: (json['iso_639_1'] as String?) ?? '',
      country: (json['iso_3166_1'] as String?) ?? '',
    );
  }
}

class TrailerInfo {
  TrailerInfo({
    required this.movie,
    required this.videoKey,
    required this.name,
  });

  final Movie movie;
  final String videoKey;
  final String name;

  String? get backdropUrl => movie.backdropUrl ?? movie.posterUrl;
}

class WishlistItem {
  WishlistItem({
    required this.id,
    required this.title,
    required this.posterPath,
  });

  final int id;
  final String title;
  final String? posterPath;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'poster': posterPath,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] as int,
      title: (map['title'] as String?) ?? '',
      posterPath: map['poster'] as String?,
    );
  }
}

