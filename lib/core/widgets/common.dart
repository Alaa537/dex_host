import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({required this.child, this.padding = const EdgeInsets.all(16), super.key});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      border: Border.all(color: AppTheme.border),
      boxShadow: const [BoxShadow(color: Color(0x2200E5A8), blurRadius: 24, spreadRadius: -14)],
    ),
    padding: padding,
    child: child,
  );
}

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.background, Color(0xFF0A1417), AppTheme.background]),
    ),
    child: child,
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext c) => const Center(child: CircularProgressIndicator(color: AppTheme.primary));
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.retry, super.key});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext c) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, size: 50, color: AppTheme.muted),
    const SizedBox(height: 12),
    Text(message, textAlign: TextAlign.center),
    const SizedBox(height: 14),
    OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
  ])));
}

class EmptyView extends StatelessWidget {
  const EmptyView({required this.title, required this.subtitle, super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext c) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.inbox_outlined, size: 54, color: AppTheme.muted),
    const SizedBox(height: 12),
    Text(title, style: Theme.of(c).textTheme.titleLarge),
    const SizedBox(height: 6),
    Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
  ])));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(text, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)));
}
