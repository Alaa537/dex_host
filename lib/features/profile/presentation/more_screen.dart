import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final items = <Widget>[
      item(context, Icons.person_outline, 'Profile', () => showProfile(context, ref)),
      item(context, Icons.security_outlined, 'Security', () => showSecurity(context, ref)),
      item(context, Icons.notifications_none, 'Announcements', () => showAnnouncements(context, ref)),
      item(context, Icons.backup_outlined, 'Backups', () => context.go('/backups')),
      item(context, Icons.rocket_launch_outlined, 'Startup Configuration', () => showStartup(context, ref)),
    ];
    if (auth.role == 'admin') items.add(item(context, Icons.admin_panel_settings_outlined, 'Admin Panel', () => context.go('/admin')));
    return ListView(padding: const EdgeInsets.all(18), children: [
      Row(children: [const CircleAvatar(radius: 28, child: Icon(Icons.person)), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(auth.username.isEmpty ? 'User' : auth.username, style: Theme.of(context).textTheme.titleLarge), Text(auth.role, style: const TextStyle(color: AppTheme.muted))])]),
      const SizedBox(height: 24),
      ...items,
      const Divider(height: 30),
      ListTile(leading: const Icon(Icons.logout, color: AppTheme.danger), title: const Text('Logout', style: TextStyle(color: AppTheme.danger)), onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
    ]);
  }
  Widget item(BuildContext context, IconData icon, String title, VoidCallback onTap) => ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}

Future<void> showProfile(BuildContext context, WidgetRef ref) async {
  final profile = await ref.read(repositoryProvider).me();
  if (!context.mounted) return;
  final rows = [profileRow('Username', profile.username), profileRow('Role', profile.role), profileRow('Status', profile.active ? 'Active' : 'Inactive'), profileRow('Server', profile.serverName ?? (profile.hasServer ? 'Assigned' : 'None')), profileRow('Bots limit', profile.maxBots?.toString() ?? 'Default'), profileRow('Expires', profile.daysLeft == null ? '—' : '${profile.daysLeft} days')];
  showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Profile', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 16), ...rows])));
}
Widget profileRow(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.muted)), Flexible(child: Text(value, textAlign: TextAlign.end))]));

Future<void> showSecurity(BuildContext context, WidgetRef ref) async {
  final oldPassword = TextEditingController(); final newPassword = TextEditingController(); final confirmPassword = TextEditingController();
  await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
    final fields = <Widget>[
      TextField(controller: oldPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
      TextField(controller: newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
      TextField(controller: confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
    ];
    return Padding(padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 18), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Security', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), ...fields, const SizedBox(height: 12), FilledButton(onPressed: () async { if (newPassword.text.length < 8 || newPassword.text != confirmPassword.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8+ characters and match'))); return; } await ref.read(repositoryProvider).changePassword(oldPassword.text, newPassword.text); if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed. Login again if requested.'))); } }, child: const Text('Change password')), TextButton(onPressed: () async { await ref.read(authProvider.notifier).logoutAll(); if (context.mounted) { Navigator.pop(context); context.go('/login'); } }, child: const Text('Logout all sessions'))]));
  });
}

Future<void> showAnnouncements(BuildContext context, WidgetRef ref) async {
  final announcements = await ref.read(repositoryProvider).announcements();
  if (!context.mounted) return;
  final List<Widget> cards = announcements
      .map((item) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.campaign_outlined,
                color: AppTheme.primary,
              ),
              title: Text(item.text),
              subtitle: Text(item.createdAt ?? ''),
            ),
          ))
      .toList();

  if (cards.isEmpty) {
    cards.add(
      const EmptyView(
        title: 'No announcements',
        subtitle: 'You are all caught up',
      ),
    );
  }
  showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: ListView(shrinkWrap: true, children: [const Text('Announcements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 12), ...cards]))));
}

Future<void> showStartup(BuildContext context, WidgetRef ref) async {
  try {
    final variables = await ref.read(repositoryProvider).startup();
    if (!context.mounted) return;
    final fields = variables.map((variable) {
      final controller = TextEditingController(text: variable.value);
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, readOnly: !variable.editable, obscureText: variable.key.toLowerCase().contains('token'), decoration: InputDecoration(labelText: variable.key, helperText: variable.description, suffixIcon: IconButton(onPressed: variable.editable ? () => ref.read(repositoryProvider).setStartup(variable.key, controller.text) : null, icon: const Icon(Icons.save)))));
    }).toList();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: ListView(shrinkWrap: true, children: [Text('Startup Configuration', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), ...fields]))));
  } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
}
