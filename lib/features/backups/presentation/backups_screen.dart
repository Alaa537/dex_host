import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/common.dart';

class BackupsScreen extends ConsumerWidget {
  const BackupsScreen({super.key});

  Future<void> createBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create backup'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    try {
      await ref.read(repositoryProvider).createBackup(controller.text);
      ref.invalidate(backupsProvider);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Backups'), actions: [IconButton(onPressed: () => createBackup(context, ref), icon: const Icon(Icons.add))]),
      body: state.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString(), retry: () => ref.invalidate(backupsProvider)),
        data: (backups) {
          if (backups.isEmpty) return const EmptyView(title: 'No backups yet', subtitle: 'Create a backup before making risky changes');
          return RefreshIndicator(onRefresh: () async { ref.invalidate(backupsProvider); }, child: ListView(padding: const EdgeInsets.all(12), children: backups.map((backup) {
            return BackupCard(
              backup: backup,
              onRestore: () => restoreBackup(context, ref, backup),
              onDownload: () => downloadBackup(ref, backup),
              onDelete: () => deleteBackup(context, ref, backup),
            );
          }).toList()));
        },
      ),
    );
  }

  Future<void> restoreBackup(BuildContext context, WidgetRef ref, BackupModel backup) async {
    if (!await confirm(context, 'Restore backup?', 'Current files may be replaced.')) return;
    try {
      await ref.read(repositoryProvider).restoreBackup(backup.uuid, false);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore started')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> downloadBackup(WidgetRef ref, BackupModel backup) async {
    final url = await ref.read(repositoryProvider).backupUrl(backup.uuid);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> deleteBackup(BuildContext context, WidgetRef ref, BackupModel backup) async {
    if (!await confirm(context, 'Delete backup?', 'This cannot be undone.')) return;
    await ref.read(repositoryProvider).deleteBackup(backup.uuid);
    ref.invalidate(backupsProvider);
  }
}

Future<bool> confirm(BuildContext context, String title, String message) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
      ],
    ),
  ) ?? false;
}

class BackupCard extends StatelessWidget {
  const BackupCard({required this.backup, required this.onRestore, required this.onDownload, required this.onDelete, super.key});
  final BackupModel backup;
  final VoidCallback onRestore;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(
      leading: const Icon(Icons.archive_outlined),
      title: Text(backup.name),
      subtitle: Text('${bytesText(backup.bytes)}  •  ${backup.createdAt ?? ''}'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) { if (value == 'restore') onRestore(); if (value == 'download') onDownload(); if (value == 'delete') onDelete(); },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'restore', child: Text('Restore')),
          PopupMenuItem(value: 'download', child: Text('Download')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    ));
  }
}
