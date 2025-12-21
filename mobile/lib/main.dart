import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: _firebaseOptionsFromEnv());
  runApp(const AppRoot());
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
      title: 'PB neteflix',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE50914)),
        pageTransitionsTheme: pageTransitions,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE50914),
          brightness: Brightness.dark,
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
                Text(
                  'PB neteflix',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE50914),
                      ),
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
  List<Movie> _nowPlaying = [];
  List<Movie> _popular = [];
  List<Movie> _searchResults = [];
  List<WishlistItem> _wishlist = [];

  late final TmdbApi _tmdb;

  @override
  void initState() {
    super.initState();
    _tmdb = TmdbApi(dotenv.env['TMDB_API_KEY'] ?? '');
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadMovies(),
      _loadWishlist(),
    ]);
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
      });
    } catch (e) {
      _showMessage('Failed to load movies: $e');
    } finally {
      if (mounted) setState(() => _loadingMovies = false);
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

  Future<void> _handleSearch() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _loadingSearch = true);
    try {
      final results = await _tmdb.search(_searchQuery.trim());
      if (!mounted) return;
      setState(() {
        _searchResults = results.take(12).toList();
        _tabIndex = 2;
      });
    } catch (e) {
      _showMessage('Search failed: $e');
    } finally {
      if (mounted) setState(() => _loadingSearch = false);
    }
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
        searchQuery: _searchQuery,
        onSearchQueryChanged: (value) => setState(() => _searchQuery = value),
        onSearch: _handleSearch,
        onToggleWishlist: _toggleWishlist,
      ),
      _PopularTab(
        popular: _popular,
        wishlist: _wishlist,
        loading: _loadingPopular,
        hasMore: _hasMorePopular,
        onLoadMore: _loadPopularMore,
        onToggleWishlist: _toggleWishlist,
      ),
      _SearchTab(
        results: _searchResults,
        wishlist: _wishlist,
        loading: _loadingSearch,
        searchQuery: _searchQuery,
        onSearchQueryChanged: (value) => setState(() => _searchQuery = value),
        onSearch: _handleSearch,
        onToggleWishlist: _toggleWishlist,
      ),
      _WishlistTab(
        wishlist: _wishlist,
        onToggleWishlist: _toggleWishlist,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PB neteflix'),
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
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.onSearch,
    required this.onToggleWishlist,
  });

  final List<Movie> nowPlaying;
  final List<Movie> popular;
  final List<WishlistItem> wishlist;
  final bool loading;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSearch;
  final ValueChanged<Movie> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'TMDB picks for you',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Trending movies, top titles, and upcoming gems.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _SearchRow(
          value: searchQuery,
          onChanged: onSearchQueryChanged,
          onSearch: onSearch,
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
        ),
        const SizedBox(height: 16),
        _MovieSection(
          title: 'Now playing',
          movies: nowPlaying,
          wishlist: wishlist,
          onToggleWishlist: onToggleWishlist,
        ),
      ],
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
  });

  final List<Movie> popular;
  final List<WishlistItem> wishlist;
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<Movie> onToggleWishlist;

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
    required this.onSearchQueryChanged,
    required this.onSearch,
    required this.onToggleWishlist,
  });

  final List<Movie> results;
  final List<WishlistItem> wishlist;
  final bool loading;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSearch;
  final ValueChanged<Movie> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
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
  });

  final List<WishlistItem> wishlist;
  final ValueChanged<Movie> onToggleWishlist;

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
            ),
            isWishlisted: true,
            onToggleWishlist: () => onToggleWishlist(
              Movie(
                id: item.id,
                title: item.title,
                overview: '',
                posterPath: item.posterPath,
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
  });

  final String title;
  final List<Movie> movies;
  final List<WishlistItem> wishlist;
  final ValueChanged<Movie> onToggleWishlist;

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
  });

  final Movie movie;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
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
    );
  }
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({
    required this.movie,
    required this.isWishlisted,
    required this.onToggleWishlist,
  });

  final Movie movie;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
    );
  }
}

class TmdbApi {
  TmdbApi(this.apiKey, {this.language = 'ko-KR'});

  final String apiKey;
  final String language;

  static const _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> nowPlaying() async {
    return _get('/movie/now_playing', {'region': 'KR'});
  }

  Future<List<Movie>> popular(int page) async {
    return _get('/movie/popular', {'page': '$page'});
  }

  Future<List<Movie>> search(String query) async {
    return _get('/search/movie', {'query': query});
  }

  Future<List<Movie>> _get(String path, Map<String, String> params) async {
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
    final results = (data['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromTmdb)
        .toList();
    return results;
  }
}

class Movie {
  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w342$posterPath';

  factory Movie.fromTmdb(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      overview: (json['overview'] as String?) ?? '',
      posterPath: json['poster_path'] as String?,
    );
  }
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
