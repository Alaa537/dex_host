import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/common.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});
  @override ConsumerState<FilesScreen> createState() => _FilesState();
}

class _FilesState extends ConsumerState<FilesScreen> {
  String dir = '/';
  String query = '';

  Future<void> upload() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.size > 25 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحد الأقصى للملف 25 MB')));
      return;
    }
    try {
      final bytes = file.bytes;
      if (bytes == null) return;
      await ref.read(repositoryProvider).uploadFile(bytes, file.name, dir);
      ref.invalidate(filesProvider(dir));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesProvider(dir));
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: TextField(onChanged: (value) => setState(() => query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search files'))),
      ListTile(
        title: Text('Files  $dir'),
        leading: dir == '/' ? null : IconButton(onPressed: () { final p = dir.split('/')..removeLast(); setState(() => dir = p.length <= 1 ? '/' : p.join('/')); }, icon: const Icon(Icons.arrow_back)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: upload, icon: const Icon(Icons.upload_file)),
          PopupMenuButton<String>(onSelected: (action) { if (action == 'folder') createFolder(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'folder', child: Text('New folder'))]),
        ]),
      ),
      Expanded(child: files.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), retry: () => ref.invalidate(filesProvider(dir))),
        data: (items) => items.isEmpty
            ? const EmptyView(title: 'No files yet', subtitle: 'Upload or create your first file')
            : RefreshIndicator(
                onRefresh: () async { ref.invalidate(filesProvider(dir)); },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.where((item) => query.trim().isEmpty || item.name.toLowerCase().contains(query.trim().toLowerCase())).length,
                  itemBuilder: (_, i) {
                    final filtered = items.where((item) => query.trim().isEmpty || item.name.toLowerCase().contains(query.trim().toLowerCase())).toList();
                    final file = filtered[i];
                    return FileTile(file: file, onOpen: () {
                      if (file.isFile) {
                        final path = dir == '/' ? '/${file.name}' : '$dir/${file.name}';
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(path: path)));
                      } else {
                        setState(() => dir = dir == '/' ? '/${file.name}' : '$dir/${file.name}');
                      }
                    }, onMenu: (action) => _action(file, action));
                  },
                ),
              ),
      )),
    ]);
  }

  Future<void> _action(FileModel file, String action) async {
    final path = dir == '/' ? '/${file.name}' : '$dir/${file.name}';
    try {
      if (action == 'download') {
        final url = await ref.read(repositoryProvider).downloadUrl(path);
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else if (action == 'delete') {
        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete file?'), content: Text('Delete ${file.name}?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])) ?? false;
        if (ok) { await ref.read(repositoryProvider).deleteFiles(dir, [file.name]); ref.invalidate(filesProvider(dir)); }
      } else if (action == 'rename') {
        final controller = TextEditingController(text: file.name);
        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          title: const Text('Rename'), content: TextField(controller: controller),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
        )) ?? false;
        if (ok) { await ref.read(repositoryProvider).rename(dir, file.name, controller.text); ref.invalidate(filesProvider(dir)); }
      } else if (action == 'copy') {
        await ref.read(repositoryProvider).batch('copy', [file.name], root: dir);
      } else if (action == 'metadata') {
        final meta = await ref.read(repositoryProvider).fileMeta(path);
        if (mounted) showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(meta.name.isEmpty ? file.name : meta.name), content: Text('Path: ${meta.path}\nSize: ${bytesText(meta.size)}\nType: ${meta.type}\nModified: ${meta.modified ?? '—'}\nPermissions: ${meta.permissions ?? '—'}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> createFolder() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('New folder'), content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Folder name')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create'))])) ?? false;
    if (ok && controller.text.trim().isNotEmpty) { await ref.read(repositoryProvider).mkdir(dir, controller.text.trim()); ref.invalidate(filesProvider(dir)); }
  }
}

class FileTile extends StatelessWidget {
  const FileTile({required this.file, required this.onOpen, required this.onMenu, super.key});
  final FileModel file;
  final VoidCallback onOpen;
  final ValueChanged<String> onMenu;
  @override Widget build(BuildContext context) => Card(child: ListTile(
    onTap: onOpen,
    leading: Icon(file.isFile ? Icons.description_outlined : Icons.folder_outlined),
    title: Text(file.name),
    subtitle: Text(file.isFile ? bytesText(file.size) : 'Folder'),
    trailing: PopupMenuButton<String>(onSelected: onMenu, itemBuilder: (_) => const [
      PopupMenuItem(value: 'download', child: Text('Download')),
      PopupMenuItem(value: 'rename', child: Text('Rename')),
      PopupMenuItem(value: 'copy', child: Text('Copy')),
      PopupMenuItem(value: 'metadata', child: Text('Properties')),
      PopupMenuItem(value: 'delete', child: Text('Delete')),
    ]),
  ));
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({required this.path, super.key});
  final String path;
  @override ConsumerState<EditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<EditorScreen> {
  final controller = TextEditingController();
  bool loading = true;
  bool saving = false;
  @override void initState() {
    super.initState();
    _loadFile();
  }
  Future<void> _loadFile() async {
    try {
      final value = await ref.read(repositoryProvider).readFile(widget.path);
      if (mounted) setState(() => controller.text = value);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  Future<void> save() async {
    setState(() => saving = true);
    try { await ref.read(repositoryProvider).writeFile(widget.path, controller.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.path), actions: [IconButton(onPressed: saving ? null : save, icon: const Icon(Icons.save))]),
    body: loading ? const LoadingView() : Padding(padding: const EdgeInsets.all(12), child: TextField(controller: controller, maxLines: null, expands: true, style: const TextStyle(fontFamily: 'monospace'), decoration: const InputDecoration(hintText: 'File content'))),
  );
}
