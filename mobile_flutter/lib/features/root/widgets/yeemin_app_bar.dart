import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_state.dart';
import '../../settings/ui_settings.dart';

const _accent = Color(0xFFE50914);

class YeeminAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const YeeminAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final ui = ref.watch(uiSettingsProvider);
    final uiCtrl = ref.read(uiSettingsProvider.notifier);
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      toolbarHeight: kToolbarHeight + 4,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/home'),
        child: Text(
          'YEEMIN',
          style: TextStyle(
            color: _accent,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      actions: [
        _SettingsMenu(
          colors: colors,
          ui: ui,
          onThemeChange: uiCtrl.setThemeMode,
          onFontDown: uiCtrl.decreaseFont,
          onFontUp: uiCtrl.increaseFont,
          onToggleMotion: uiCtrl.toggleReduceMotion,
          onLogout: () async {
            await ref.read(authStateProvider.notifier).signOut();
            if (context.mounted) context.go('/auth');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({
    required this.colors,
    required this.ui,
    required this.onThemeChange,
    required this.onFontDown,
    required this.onFontUp,
    required this.onToggleMotion,
    required this.onLogout,
  });

  final ColorScheme colors;
  final UiSettings ui;
  final ValueChanged<ThemeMode> onThemeChange;
  final VoidCallback onFontDown;
  final VoidCallback onFontUp;
  final VoidCallback onToggleMotion;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return _SettingsButton(
      colors: colors,
      ui: ui,
      onThemeChange: onThemeChange,
      onFontDown: onFontDown,
      onFontUp: onFontUp,
      onToggleMotion: onToggleMotion,
      onLogout: onLogout,
    );
  }
}

class _SettingsButton extends StatefulWidget {
  const _SettingsButton({
    required this.colors,
    required this.ui,
    required this.onThemeChange,
    required this.onFontDown,
    required this.onFontUp,
    required this.onToggleMotion,
    required this.onLogout,
  });

  final ColorScheme colors;
  final UiSettings ui;
  final ValueChanged<ThemeMode> onThemeChange;
  final VoidCallback onFontDown;
  final VoidCallback onFontUp;
  final VoidCallback onToggleMotion;
  final Future<void> Function() onLogout;

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  final _anchorKey = GlobalKey();

  Future<void> _openMenu() async {
    final renderBox = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final button = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    final rect = Rect.fromLTWH(button.dx, button.dy, size.width, size.height);

    await showMenu(
      context: context,
      color: Colors.transparent,
      elevation: 0,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: [
        PopupMenuItem<int>(
          padding: EdgeInsets.zero,
          enabled: false,
          child: _SettingsPanel(
            ui: widget.ui,
            onThemeChange: widget.onThemeChange,
            onFontDown: widget.onFontDown,
            onFontUp: widget.onFontUp,
            onToggleMotion: widget.onToggleMotion,
            onLogout: widget.onLogout,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return GestureDetector(
      key: _anchorKey,
      onTap: _openMenu,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(10),
          color: colors.surfaceVariant.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, color: colors.onSurface, size: 18),
            const SizedBox(width: 6),
            Text(
              '설정',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.ui,
    required this.onThemeChange,
    required this.onFontDown,
    required this.onFontUp,
    required this.onToggleMotion,
    required this.onLogout,
  });

  final UiSettings ui;
  final ValueChanged<ThemeMode> onThemeChange;
  final VoidCallback onFontDown;
  final VoidCallback onFontUp;
  final VoidCallback onToggleMotion;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    const panelBg = Color(0xFF1F2845);
    const panelBorder = Color(0xFF2B3455);
    const muted = Color(0xFFA6B0CB);

    void close() => Navigator.of(context).pop();

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(text: '테마', color: muted),
          const SizedBox(height: 8),
          Row(
            children: [
              _PillButton(
                label: '라이트',
                active: ui.themeMode == ThemeMode.light,
                onTap: () {
                  onThemeChange(ThemeMode.light);
                  close();
                },
              ),
              const SizedBox(width: 10),
              _PillButton(
                label: '다크',
                active: ui.themeMode == ThemeMode.dark,
                onTap: () {
                  onThemeChange(ThemeMode.dark);
                  close();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Label(text: '폰트 크기', color: muted),
          const SizedBox(height: 8),
          Row(
            children: [
              _SquareButton(
                icon: Icons.remove,
                onTap: () {
                  onFontDown();
                  close();
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    ui.fontLevel.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              _SquareButton(
                icon: Icons.add,
                onTap: () {
                  onFontUp();
                  close();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Label(text: '애니메이션', color: muted),
          const SizedBox(height: 8),
          Row(
            children: [
              _PillButton(
                label: '끄기',
                active: ui.reduceMotion,
                onTap: () {
                  if (!ui.reduceMotion) {
                    onToggleMotion();
                  }
                  close();
                },
              ),
              const SizedBox(width: 10),
              _PillButton(
                label: '켜기',
                active: !ui.reduceMotion,
                onTap: () {
                  if (ui.reduceMotion) {
                    onToggleMotion();
                  }
                  close();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {
              close();
              onLogout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              '로그아웃',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _accent : const Color(0xFF12182D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2B3455)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF12182D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B3455)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
