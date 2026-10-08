import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/localization/strings.dart';
import '../../../core/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.register, super.key});
  final bool register;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final invite = TextEditingController();
  final confirmPassword = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    invite.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final user = username.text.trim();
    if (user.length < 3 || user.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be 3–20 characters')),
      );
      return;
    }
    if (password.text.length < 8 ||
        (widget.register && password.text != confirmPassword.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be 8+ characters and match')),
      );
      return;
    }

    final auth = ref.read(authProvider.notifier);
    final ok = widget.register
        ? await auth.register(user, password.text, invite.text.trim())
        : await auth.login(user, password.text);

    if (ok && mounted) {
      final role = ref.read(authProvider).role;
      context.go(role == 'admin' ? '/admin' : '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(authProvider);
    final title = widget.register ? strings.register : strings.login;

    return Directionality(
      textDirection: strings.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.background,
                Color(0xFF0A1417),
                AppTheme.background,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.cloud_done_rounded,
                          size: 66,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'DEX Host',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Powerful Hosting. Simplified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: username,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: strings.username,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: hidePassword,
                          textInputAction: widget.register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: (_) => submit(),
                          decoration: InputDecoration(
                            labelText: strings.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => hidePassword = !hidePassword,
                              ),
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),
                        if (widget.register) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: confirmPassword,
                            obscureText: hidePassword,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: invite,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => submit(),
                            decoration: const InputDecoration(
                              labelText: 'Invite code (optional)',
                              prefixIcon: Icon(Icons.key_outlined),
                            ),
                          ),
                        ],
                        if (state.error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: .22),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: state.loading ? null : submit,
                            child: state.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(title),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(
                            widget.register ? '/login' : '/register',
                          ),
                          child: Text(
                            widget.register
                                ? 'لديك حساب؟ تسجيل الدخول'
                                : 'ليس لديك حساب؟ إنشاء حساب',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
