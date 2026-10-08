import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class AdminScreen extends ConsumerStatefulWidget { const AdminScreen({super.key}); @override ConsumerState<AdminScreen> createState() => _AdminState(); }
class _AdminState extends ConsumerState<AdminScreen> {
  int tab = 0; String search = '';
  @override Widget build(BuildContext context) {
    final pages = <Widget>[overview, requests, users, pool, audit, settings];
    return Scaffold(appBar: AppBar(title: const Text('DEX Host Admin')), body: Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12), child: SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Overview')), ButtonSegment(value: 1, label: Text('Requests')), ButtonSegment(value: 2, label: Text('Users')), ButtonSegment(value: 3, label: Text('Pool')), ButtonSegment(value: 4, label: Text('Audit')), ButtonSegment(value: 5, label: Text('Settings'))], selected: {tab}, onSelectionChanged: (value) => setState(() => tab = value.first))),
      Expanded(child: pages[tab]),
    ]));
  }

  Widget get overview => FutureBuilder<AdminStats>(future: ref.read(repositoryProvider).adminStats(), builder: (context, snapshot) {
    if (!snapshot.hasData) return const LoadingView();
    final stats = snapshot.data!;
    return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(16), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5, children: [_stat('Users', stats.users), _stat('Banned', stats.banned), _stat('New 7 days', stats.new7Days), _stat('Pool total', stats.poolTotal), _stat('Pool free', stats.poolFree), _stat('Logins 24h', stats.logins24h)]);
  });
  Widget _stat(String title, int value) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: AppTheme.muted)), const SizedBox(height: 8), Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary))])));

  Widget get requests => FutureBuilder<List<AdminRequest>>(
    future: ref.read(repositoryProvider).adminRequests(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
      if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), retry: () => setState(() {}));
      final list = snapshot.data ?? const <AdminRequest>[];
      if (list.isEmpty) return const EmptyView(title: 'No pending requests', subtitle: 'New registration requests will appear here.');
      return RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final request = list[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
                title: Text(request.username, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${request.status} • ${request.createdAt ?? '—'}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Approve',
                      color: AppTheme.success,
                      onPressed: () => approveRequest(context, request),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Reject',
                      color: AppTheme.danger,
                      onPressed: () => rejectRequest(context, request),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );

  Future<void> approveRequest(BuildContext context, AdminRequest request) async {
    final days = TextEditingController(text: '30');
    final maxBots = TextEditingController(text: '3');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Approve ${request.username}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Days')),
            const SizedBox(height: 10),
            TextField(controller: maxBots, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max bots')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve')),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      await ref.read(repositoryProvider).approveRequest(
        request.id,
        days: int.tryParse(days.text.trim()),
        maxBots: int.tryParse(maxBots.text.trim()),
      );
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved')));
      setState(() {});
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> rejectRequest(BuildContext context, AdminRequest request) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject ${request.username}?'),
        content: TextField(controller: reason, maxLength: 200, decoration: const InputDecoration(labelText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      await ref.read(repositoryProvider).rejectRequest(request.id, reason.text.trim());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
      setState(() {});
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget get users => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search users'), onChanged: (value) => setState(() => search = value))),
    Expanded(child: FutureBuilder<List<AdminUserModel>>(future: ref.read(repositoryProvider).adminUsers(search: search), builder: (context, snapshot) {
      if (!snapshot.hasData) return const LoadingView();
      final list = snapshot.data!;
      if (list.isEmpty) return const EmptyView(title: 'No users', subtitle: 'No matching users found');
      return ListView(padding: const EdgeInsets.all(12), children: list.map((user) => Card(child: ListTile(title: Text(user.username), subtitle: Text('${user.role} • ${user.banned ? 'Banned' : 'Active'} • ${user.serverId ?? 'No server'}'), leading: Icon(user.banned ? Icons.block : Icons.person_outline, color: user.banned ? AppTheme.danger : AppTheme.primary), trailing: PopupMenuButton<String>(onSelected: (value) => userAction(context, user, value), itemBuilder: (_) => const [PopupMenuItem(value: 'ban', child: Text('Ban')), PopupMenuItem(value: 'unban', child: Text('Unban')), PopupMenuItem(value: 'logout', child: Text('Force logout')), PopupMenuItem(value: 'delete', child: Text('Delete account'))])))).toList());
    })),
  ]);

  Future<void> userAction(BuildContext context, AdminUserModel user, String action) async {
    final repo = ref.read(repositoryProvider);
    try {
      if (action == 'ban') await repo.banUser(user.id, 'Banned by admin', true);
      if (action == 'unban') await repo.unbanUser(user.id);
      if (action == 'logout') await repo.forceLogout(user.id);
      if (action == 'delete') { final confirmed = await confirmAdmin(context, 'Delete account?', 'The account will be deleted and files will be kept.'); if (confirmed) await repo.deleteUser(user.id, wipe: false); }
      setState(() {});
    } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Widget get pool => FutureBuilder<List<PoolServerModel>>(future: ref.read(repositoryProvider).pool(live: true), builder: (context, snapshot) {
    if (!snapshot.hasData) return const LoadingView();
    final cards = snapshot.data!.map((server) => Card(child: ListTile(title: Text(server.label.isEmpty ? server.serverId : server.label), subtitle: Text('${server.state ?? 'Unknown'} • ${server.username ?? 'Available'}'), trailing: IconButton(onPressed: () async { await ref.read(repositoryProvider).deletePool(server.id); setState(() {}); }, icon: const Icon(Icons.delete_outline))))).toList();
    return ListView(padding: const EdgeInsets.all(12), children: [FilledButton.icon(onPressed: () => addPool(context), icon: const Icon(Icons.add), label: const Text('Add server')), const SizedBox(height: 12), ...cards]);
  });

  Future<void> addPool(BuildContext context) async {
    final key = TextEditingController(); final serverId = TextEditingController(); final label = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Add server'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')), TextField(controller: serverId, decoration: const InputDecoration(labelText: 'Server ID')), TextField(controller: key, obscureText: true, decoration: const InputDecoration(labelText: 'API Key'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))])) ?? false;
    if (ok) { await ref.read(repositoryProvider).addPool(key.text, serverId.text, label.text); setState(() {}); }
  }

  Widget get audit => FutureBuilder<List<AuditLogModel>>(future: ref.read(repositoryProvider).audit(), builder: (context, snapshot) {
    if (!snapshot.hasData) return const LoadingView();
    return ListView(padding: const EdgeInsets.all(12), children: snapshot.data!.map((entry) => Card(child: ListTile(title: Text(entry.action), subtitle: Text('${entry.ts} • ${entry.username ?? entry.userId ?? 'system'}\n${entry.detail ?? ''}')))).toList());
  });

  Widget get settings => FutureBuilder<Map<String, dynamic>>(future: ref.read(repositoryProvider).adminSettings(), builder: (context, snapshot) {
    if (!snapshot.hasData) return const LoadingView();
    final data = snapshot.data!; final maintenance = data['maintenance'] == true; final registration = data['registration_open'] != false; final invite = TextEditingController(text: data['invite_code']?.toString() ?? '');
    return ListView(padding: const EdgeInsets.all(18), children: [SwitchListTile(title: const Text('Maintenance mode'), value: maintenance, onChanged: (value) async { await ref.read(repositoryProvider).updateAdminSettings(maintenance: value); setState(() {}); }), SwitchListTile(title: const Text('Registration open'), value: registration, onChanged: (value) async { await ref.read(repositoryProvider).updateAdminSettings(registrationOpen: value); setState(() {}); }), TextField(controller: invite, decoration: const InputDecoration(labelText: 'Invite code')), const SizedBox(height: 12), FilledButton(onPressed: () async { await ref.read(repositoryProvider).updateAdminSettings(inviteCode: invite.text); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'))); }, child: const Text('Save settings'))]);
  });
}
Future<bool> confirmAdmin(BuildContext context, String title, String message) async => await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue'))])) ?? false;
