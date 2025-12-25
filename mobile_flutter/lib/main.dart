import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'features/settings/ui_settings.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Optional sanity check: surface missing env keys early in dev.
  AppConfig.warnIfMissing();
  runApp(const ProviderScope(child: PbTeamApp()));
}

class PbTeamApp extends ConsumerWidget {
  const PbTeamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final ui = ref.watch(uiSettingsProvider);
    return MaterialApp.router(
      title: 'PBTeam',
      debugShowCheckedModeBanner: false,
      themeMode: ui.themeMode,
      theme: _buildTheme(Brightness.light, ui.reduceMotion),
      darkTheme: _buildTheme(Brightness.dark, ui.reduceMotion),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(ui.fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}

ThemeData _buildTheme(Brightness brightness, bool reduceMotion) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    ),
    useMaterial3: true,
  );

  final transitions = reduceMotion
      ? const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionsBuilder(),
            TargetPlatform.iOS: _NoTransitionsBuilder(),
            TargetPlatform.fuchsia: _NoTransitionsBuilder(),
            TargetPlatform.linux: _NoTransitionsBuilder(),
            TargetPlatform.macOS: _NoTransitionsBuilder(),
            TargetPlatform.windows: _NoTransitionsBuilder(),
          },
        )
      : const PageTransitionsTheme();

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: base.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
    ),
    pageTransitionsTheme: transitions,
  );
}

/// Disables page transitions when reduceMotion is on.
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
