import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/network/live_log_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/common.dart';
import '../../../core/theme/app_theme.dart';

class BotsScreen extends ConsumerWidget {
  const BotsScreen({super.key});

  Future<void> addBot(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false);
    final file = result?.files.single;
    if (file == null || !file.name.toLowerCase().endsWith('.py') || file.name == 'app.py') {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a Python file other than app.py')));
      return;
    }
    try {
      final bytes = file.bytes;
      if (bytes == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read the selected file')));
        return;
      }
      await ref.read(repositoryProvider).uploadBot(bytes, file.name, env: jsonEncode({}));
      ref.invalidate(botsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bot uploaded')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(botsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bots'), actions: [IconButton(onPressed: () => addBot(context, ref), icon: const Icon(Icons.add))]),
      body: state.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString(), retry: () => ref.invalidate(botsProvider)),
        data: (bots) {
          if (bots.isEmpty) return const EmptyView(title: 'No bots yet', subtitle: 'Deploy your first Python bot from DEX Host');
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(botsProvider); },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: bots.map<Widget>((bot) => BotCard(
                bot: bot,
                onToggle: (enabled) async { await ref.read(repositoryProvider).toggleBot(bot.file, enabled); ref.invalidate(botsProvider); },
                onRestart: () async { await ref.read(repositoryProvider).restartBot(bot.file); ref.invalidate(botsProvider); },
                onDelete: () async { await ref.read(repositoryProvider).removeBot(bot.file, false); ref.invalidate(botsProvider); },
                onLogs: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BotLogsScreen(file: bot.file))),
                onEnvironment: () => showEnvironment(context, ref, bot),
                onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BotDetailsScreen(bot: bot))),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}

class BotCard extends StatelessWidget {
  const BotCard({required this.bot, required this.onToggle, required this.onRestart, required this.onDelete, required this.onLogs, required this.onEnvironment, required this.onOpen, super.key});
  final BotModel bot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRestart;
  final VoidCallback onDelete;
  final VoidCallback onLogs;
  final VoidCallback onEnvironment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          ListTile(
            onTap: onOpen,
            leading: CircleAvatar(backgroundColor: statusColor(bot.state).withValues(alpha: .18), child: Icon(Icons.smart_toy_outlined, color: statusColor(bot.state))),
            title: Text(bot.file, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Row(children: [Icon(Icons.circle, size: 9, color: statusColor(bot.state)), const SizedBox(width: 6), Text(bot.state)]),
            trailing: Switch(value: bot.enabled, onChanged: onToggle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: metric('Uptime', bot.startedAt ?? '--')),
              Expanded(child: metric('Restarts', '${bot.restarts}')),
              IconButton(tooltip: 'Logs', onPressed: onLogs, icon: const Icon(Icons.terminal)),
              IconButton(tooltip: 'Environment', onPressed: onEnvironment, icon: const Icon(Icons.tune)),
              PopupMenuButton<String>(onSelected: (value) { if (value == 'restart') onRestart(); if (value == 'delete') onDelete(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'restart', child: Text('Restart')), PopupMenuItem(value: 'delete', child: Text('Remove bot'))]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget metric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]);
  static Color statusColor(String state) { final value = state.toLowerCase(); if (value == 'running') return Colors.greenAccent; if (value.contains('crash')) return Colors.redAccent; if (value.contains('start') || value.contains('restart')) return Colors.orangeAccent; if (value == 'disabled') return Colors.grey; return Colors.white54; }
}

class BotDetailsScreen extends ConsumerWidget {
  const BotDetailsScreen({required this.bot, super.key});
  final BotModel bot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = BotCard.statusColor(bot.state);
    return Scaffold(appBar: AppBar(title: Text(bot.file)), body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(backgroundColor: color.withValues(alpha: .18), child: Icon(Icons.smart_toy_outlined, color: color)), const SizedBox(width: 12), Expanded(child: Text(bot.file, style: Theme.of(context).textTheme.headlineSmall)), Text(bot.state, style: TextStyle(color: color, fontWeight: FontWeight.w700))]), const SizedBox(height: 22), Row(children: [detail('Enabled', bot.enabled ? 'Yes' : 'No'), detail('Restarts', '${bot.restarts}'), detail('Exit code', bot.lastExitCode?.toString() ?? '—')]), const SizedBox(height: 12), Text('Started at: ${bot.startedAt ?? '—'}', style: const TextStyle(color: AppTheme.textPrimary))]))),
      const SizedBox(height: 14), const SectionTitle('Actions'),
      Wrap(spacing: 10, runSpacing: 10, children: [FilledButton.icon(onPressed: () async { await ref.read(repositoryProvider).toggleBot(bot.file, true); }, icon: const Icon(Icons.play_arrow), label: const Text('Start')), OutlinedButton.icon(onPressed: () async { await ref.read(repositoryProvider).toggleBot(bot.file, false); }, icon: const Icon(Icons.stop), label: const Text('Stop')), OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BotLogsScreen(file: bot.file))), icon: const Icon(Icons.terminal), label: const Text('Logs')), OutlinedButton.icon(onPressed: () => showEnvironment(context, ref, bot), icon: const Icon(Icons.tune), label: const Text('Environment'))]),
      const SizedBox(height: 18), const SectionTitle('Environment variables'), if (bot.envKeys.isEmpty) const Text('No variables configured', style: TextStyle(color: Colors.white54)), ...bot.envKeys.map((key) => ListTile(leading: const Icon(Icons.key_outlined), title: Text(key), subtitle: const Text('Value hidden for security'))),
    ]));
  }
  Widget detail(String label, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

Future<void> showEnvironment(BuildContext context, WidgetRef ref, BotModel bot) async {
  final key = TextEditingController();
  final value = TextEditingController();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Environment • ${bot.file}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (bot.envKeys.isEmpty) const Text('No variables configured'),
        ...bot.envKeys.map((name) => ListTile(leading: const Icon(Icons.key_outlined), title: Text(name), subtitle: const Text('••••••••'), trailing: IconButton(onPressed: () async { await ref.read(repositoryProvider).deleteBotEnv(bot.file, name); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline)))),
        const Divider(),
        TextField(controller: key, decoration: const InputDecoration(labelText: 'Variable key')),
        const SizedBox(height: 8),
        TextField(controller: value, obscureText: true, decoration: const InputDecoration(labelText: 'Secret value')),
        const SizedBox(height: 12),
        FilledButton(onPressed: () async { await ref.read(repositoryProvider).setBotEnv(bot.file, key.text.trim(), value.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Save variable')),
      ]),
    ),
  );
}

class BotLogsScreen extends ConsumerStatefulWidget {
  const BotLogsScreen({required this.file, super.key});
  final String file;
  @override ConsumerState<BotLogsScreen> createState() => _BotLogsState();
}

class _BotLogsState extends ConsumerState<BotLogsScreen> {
  final searchController = TextEditingController();
  final scrollController = ScrollController();
  LogLevel filter = LogLevel.all;
  String search = '';
  bool autoScroll = true;
  bool newLogs = false;

  @override
  void initState() { super.initState(); scrollController.addListener(_onScroll); }
  @override
  void dispose() { searchController.dispose(); scrollController.dispose(); super.dispose(); }
  void _onScroll() { if (!scrollController.hasClients || !mounted) return; final atBottom = scrollController.position.maxScrollExtent - scrollController.offset < 80; setState(() { if (atBottom) { newLogs = false; autoScroll = true; } else { newLogs = true; autoScroll = false; } }); }
  void _scrollToEnd() { if (!scrollController.hasClients) return; scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut); setState(() { newLogs = false; autoScroll = true; }); }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(liveLogProvider(widget.file));
    final state = controller.state;
    final lines = controller.visibleLines(filter: filter, search: search);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && autoScroll && scrollController.hasClients) scrollController.jumpTo(scrollController.position.maxScrollExtent); });
    return Scaffold(
      appBar: AppBar(title: Row(children: [Text(widget.file), const SizedBox(width: 10), _statusChip(state.connection)]), actions: [IconButton(tooltip: 'Refresh', onPressed: controller.refresh, icon: const Icon(Icons.refresh)), IconButton(tooltip: 'Clear view', onPressed: controller.clearView, icon: const Icon(Icons.clear_all)), PopupMenuButton<String>(onSelected: (value) async { if (value == 'server') { final ok = await _confirmClear(context); if (ok) await controller.clearServer(); } if (value == 'copy') await Clipboard.setData(ClipboardData(text: lines.map((e) => e.text).join('\n'))); }, itemBuilder: (_) => const [PopupMenuItem(value: 'copy', child: Text('Copy visible logs')), PopupMenuItem(value: 'server', child: Text('Clear server logs'))])]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 6), child: Row(children: [Expanded(child: TextField(controller: searchController, onChanged: (value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search logs'))), const SizedBox(width: 8), DropdownButton<LogLevel>(value: filter, onChanged: (value) { if (value != null) setState(() => filter = value); }, items: LogLevel.values.map((value) => DropdownMenuItem(value: value, child: Text(levelLabel(value)))).toList())])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [IconButton(tooltip: state.paused ? 'Resume' : 'Pause', onPressed: state.paused ? controller.resume : controller.pause, icon: Icon(state.paused ? Icons.play_arrow : Icons.pause)), const Text('Live updates'), const Spacer(), IconButton(tooltip: 'Auto scroll', onPressed: () => setState(() => autoScroll = !autoScroll), icon: Icon(autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center, color: autoScroll ? Colors.greenAccent : Colors.white54))])),
        Expanded(child: Container(color: const Color(0xFF030504), child: lines.isEmpty ? const Center(child: Text('No logs yet. Start or restart the bot to see output.', style: TextStyle(color: Colors.white54))) : ListView.builder(controller: scrollController, padding: const EdgeInsets.all(12), itemCount: lines.length, itemBuilder: (_, index) => _logLine(lines[index])))),
        if (newLogs) Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(onPressed: _scrollToEnd, icon: const Icon(Icons.arrow_downward), label: const Text('New logs')))),
        Container(height: 30, padding: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0xFF0B1210), alignment: Alignment.centerLeft, child: Text(state.lastError ?? statusLabel(state.connection), style: const TextStyle(fontSize: 12, color: Colors.white54))),
      ]),
    );
  }

  Widget _statusChip(LiveLogConnection status) { final live = status == LiveLogConnection.live; final color = live ? Colors.greenAccent : status == LiveLogConnection.reconnecting || status == LiveLogConnection.connecting ? Colors.orangeAccent : Colors.redAccent; return Row(children: [Icon(Icons.circle, size: 9, color: color), const SizedBox(width: 4), Text(statusLabel(status), style: TextStyle(fontSize: 12, color: color))]); }
  Widget _logLine(LogLine line) { final color = line.level == LogLevel.error ? Colors.redAccent : line.level == LogLevel.warning ? Colors.orangeAccent : line.level == LogLevel.success ? Colors.greenAccent : line.level == LogLevel.debug ? Colors.blueAccent : Colors.white70; final text = line.text; if (search.isEmpty) return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(text, style: TextStyle(fontFamily: 'monospace', color: color))); final parts = text.split(RegExp('(${RegExp.escape(search)})', caseSensitive: false)); return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text.rich(TextSpan(children: parts.map((part) => TextSpan(text: part, style: TextStyle(fontFamily: 'monospace', color: part.toLowerCase() == search.toLowerCase() ? Colors.black : color, backgroundColor: part.toLowerCase() == search.toLowerCase() ? Colors.yellowAccent : null))).toList()))); }
  String levelLabel(LogLevel value) => value == LogLevel.all ? 'ALL' : value.name.toUpperCase();
  String statusLabel(LiveLogConnection value) => value == LiveLogConnection.live ? 'LIVE' : value == LiveLogConnection.reconnecting ? 'RECONNECTING' : value == LiveLogConnection.connecting ? 'CONNECTING' : 'OFFLINE';
  Future<bool> _confirmClear(BuildContext context) async => await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Clear server logs?'), content: const Text('This permanently deletes the bot logs from the server.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear'))])) ?? false;
}
