import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_state.dart';

// Palette matching the React Native version.
const _bg = Color(0xFF05070F);
const _card = Color(0xFF0B1021);
const _border = Color(0xFF1F2937);
const _text = Color(0xFFF8FAFC);
const _muted = Color(0xFF9CA3AF);
const _accent = Color(0xFFE50914);

enum _AuthMode { login, signup }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  _AuthMode _mode = _AuthMode.login;
  bool _curtainOpen = false;
  bool _busy = false;
  double _stageWidth = 0;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          duration: const Duration(milliseconds: 750),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.forward) {
            setState(() => _curtainOpen = true);
          }
          if (status == AnimationStatus.dismissed) {
            setState(() => _curtainOpen = false);
          }
        });
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleCurtain(bool open) async {
    if (open) {
      await _controller.forward();
    } else {
      await _controller.reverse();
    }
  }

  Future<void> _switchMode(_AuthMode next) async {
    if (_mode == next) return;
    await _toggleCurtain(false);
    setState(() => _mode = next);
    await _toggleCurtain(true);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_mode == _AuthMode.signup &&
        _password.text.trim() != _passwordConfirm.text.trim()) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }
    setState(() => _busy = true);
    final auth = ref.read(authStateProvider.notifier);
    try {
      if (_mode == _AuthMode.login) {
        await auth.signInWithEmail(_email.text.trim(), _password.text.trim());
      } else {
        await auth.signUpWithEmail(_email.text.trim(), _password.text.trim());
      }
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleLogin() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = ref.read(authStateProvider.notifier);
    try {
      await auth.signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = _mode == _AuthMode.signup ? 500.0 : 410.0;
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.45, 1)),
    );
    final slide = Tween<double>(begin: 16, end: 0).animate(_progress);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'YEEMIN',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: const Color(0xFF060910),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stageWidth = _stageWidth == 0
                            ? constraints.maxWidth
                            : _stageWidth;
                        final halfWidth = stageWidth / 2;
                        if (_stageWidth != constraints.maxWidth) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _stageWidth = constraints.maxWidth;
                              });
                            }
                          });
                        }
                        return Stack(
                          children: [
                            _CurtainPanel(
                              progress: _progress,
                              offset: -halfWidth,
                              alignLeft: true,
                              stageWidth: stageWidth,
                            ),
                            _CurtainPanel(
                              progress: _progress,
                              offset: halfWidth,
                              alignLeft: false,
                              stageWidth: stageWidth,
                            ),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                return Positioned.fill(
                                  child: Opacity(
                                    opacity: fade.value,
                                    child: Transform.translate(
                                      offset: Offset(0, slide.value),
                                      child: AbsorbPointer(
                                        absorbing: !_curtainOpen,
                                        child: Container(
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            32,
                                            16,
                                            10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _card,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(color: _border),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 10,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _AuthTabs(
                                                mode: _mode,
                                                onSwitch: _switchMode,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _mode == _AuthMode.login
                                                    ? '로그인'
                                                    : '회원가입',
                                                style: const TextStyle(
                                                  color: _text,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              _InputField(
                                                controller: _email,
                                                hint: '이메일',
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                              ),
                                              _InputField(
                                                controller: _password,
                                                hint: '비밀번호',
                                                obscure: true,
                                              ),
                                              if (_mode == _AuthMode.signup)
                                                _InputField(
                                                  controller: _passwordConfirm,
                                                  hint: '비밀번호 확인',
                                                  obscure: true,
                                                ),
                                              const SizedBox(height: 6),
                                              _PrimaryButton(
                                                label: _mode == _AuthMode.login
                                                    ? '로그인하기'
                                                    : '회원가입하기',
                                                onPressed: _submit,
                                                busy: _busy,
                                              ),
                                              const SizedBox(height: 10),
                                              _ProviderButton(
                                                label: 'Google로 로그인',
                                                onPressed: _googleLogin,
                                                busy: _busy,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleCurtain(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _accent),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '입장하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurtainPanel extends StatelessWidget {
  const _CurtainPanel({
    required this.progress,
    required this.offset,
    required this.alignLeft,
    required this.stageWidth,
  });

  final Animation<double> progress;
  final double offset;
  final bool alignLeft;
  final double stageWidth;

  @override
  Widget build(BuildContext context) {
    final stripes = List.generate(14, (i) => i);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return Positioned(
          top: 0,
          bottom: 0,
          left: alignLeft ? 0 : null,
          right: alignLeft ? null : 0,
          width: stageWidth / 2,
          child: Transform.translate(
            offset: Offset(progress.value * offset, 0),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE02020),
          borderRadius: BorderRadius.horizontal(
            left: alignLeft ? Radius.zero : const Radius.circular(16),
            right: alignLeft ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: stripes
                .map(
                  (idx) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color.fromRGBO(0, 0, 0, 0.08),
                          const Color.fromRGBO(0, 0, 0, 0.16),
                          idx.isEven ? 0.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.mode, required this.onSwitch});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onSwitch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabButton(
          label: 'LOGIN',
          active: mode == _AuthMode.login,
          onTap: () => onSwitch(_AuthMode.login),
        ),
        _TabButton(
          label: 'SIGN UP',
          active: mode == _AuthMode.signup,
          onTap: () => onSwitch(_AuthMode.signup),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: _border),
            color: active ? _accent : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : _text,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(color: _text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted),
          filled: true,
          fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _card,
        ),
        onPressed: busy ? null : onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
