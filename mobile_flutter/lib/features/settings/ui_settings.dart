import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UiSettings {
  const UiSettings({
    required this.themeMode,
    required this.fontLevel,
    required this.reduceMotion,
  });

  final ThemeMode themeMode;
  final int fontLevel; // 1~7
  final bool reduceMotion;

  double get fontScale => 0.9 + (fontLevel - 1) * 0.05; // 0.9 ~ 1.2

  UiSettings copyWith({
    ThemeMode? themeMode,
    int? fontLevel,
    bool? reduceMotion,
  }) {
    return UiSettings(
      themeMode: themeMode ?? this.themeMode,
      fontLevel: fontLevel ?? this.fontLevel,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

class UiSettingsNotifier extends Notifier<UiSettings> {
  @override
  UiSettings build() {
    return const UiSettings(
      themeMode: ThemeMode.dark,
      fontLevel: 4,
      reduceMotion: false,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void increaseFont() {
    final next = (state.fontLevel + 1).clamp(1, 7);
    state = state.copyWith(fontLevel: next);
  }

  void decreaseFont() {
    final next = (state.fontLevel - 1).clamp(1, 7);
    state = state.copyWith(fontLevel: next);
  }

  void toggleReduceMotion() {
    state = state.copyWith(reduceMotion: !state.reduceMotion);
  }
}

final uiSettingsProvider =
    NotifierProvider<UiSettingsNotifier, UiSettings>(UiSettingsNotifier.new);
