import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/installer.dart';
import '../data/db.dart';
import '../update/update_checker.dart';
import '../../../app/theme.dart';
import 'job_progress.dart';
import 'providers.dart';

class InstalledScreen extends ConsumerWidget {
  const InstalledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dicts = ref.watch(installedProvider);
    final jobs = ref.watch(jobsProvider);
    final repo = ref.read(repoProvider);
    final importJob = jobs['import'];

    return Scaffold(
      appBar: AppBar(title: const Text('Installed dictionaries')),
      body: dicts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          padding: pagePadding(context, top: 8),
          children: [
            Padding(
              padding: EdgeInsets.zero,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: importJob?.running == true
                        ? null
                        : () => _import(context, ref),
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Import'),
                  ),
                  OutlinedButton.icon(
                    onPressed: list.isEmpty
                        ? null
                        : () => _checkUpdates(context, ref, list),
                    icon: const Icon(Icons.update),
                    label: const Text('Check for updates'),
                  ),
                  OutlinedButton.icon(
                    onPressed: list.isEmpty
                        ? null
                        : () => _deleteAll(context, ref),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Delete all'),
                  ),
                ],
              ),
            ),
            if (importJob != null)
              Card(
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: importJob.error != null
                      ? _ErrorLine(
                          '${importJob.error}',
                          onClose: () =>
                              ref.read(jobsProvider.notifier).clear('import'),
                        )
                      : JobProgress(
                          importJob,
                          onCancel: () =>
                              ref.read(jobsProvider.notifier).cancel('import'),
                        ),
                ),
              ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No dictionaries yet. Import a Yomitan .zip or download one from Recommended.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Section(
                title: 'Used for look-ups, top first',
                children: [
                  SwitchListTile(
                    title: const Text('All'),
                    value: list.every((d) => d.enabled),
                    onChanged: repo.setAllEnabled,
                  ),
                  for (final (i, d) in list.indexed)
                    _DictTile(d, i, list.length, jobs['update:${d.id}']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (picked == null) return;
    var path = picked.path;
    File? copy;
    if (path == null) {
      // content:// URI (Android SAF): stream it to a temp file the isolate can open.
      copy = File(
        p.join(
          ref.read(appPathsProvider).tempDir,
          'import_${DateTime.now().microsecondsSinceEpoch}.zip',
        ),
      );
      final sink = copy.openWrite();
      await sink.addStream(picked.readAsByteStream());
      await sink.close();
      path = copy.path;
    }
    final job = await ref
        .read(jobsProvider.notifier)
        .start('import', ref.read(installerProvider).importFile(path));
    copy?.delete().ignore();
    if (job.state is Installed && context.mounted) {
      final r = (job.state as Installed).result;
      _snack(
        context,
        r.replacedRevision == null
            ? 'Imported ${r.title}'
            : 'Updated ${r.title} (was rev.${r.replacedRevision})',
      );
    }
  }

  Future<void> _checkUpdates(
    BuildContext context,
    WidgetRef ref,
    List<Dictionary> list,
  ) async {
    _snack(context, 'Checking for updates…');
    final res = await checkForUpdates(ref.read(dioProvider), list);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (res.updates.isEmpty) {
      final notUpdatable = list
          .where((d) => !d.isUpdatable || d.indexUrl == null)
          .length;
      _snack(
        context,
        [
          'All dictionaries are up to date.',
          if (notUpdatable > 0) '$notUpdatable not updatable.',
          if (res.failures.isNotEmpty)
            'Failed: ${res.failures.keys.join(', ')}',
        ].join(' '),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Updates available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final u in res.updates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(u.dictionary.title),
                subtitle: Text(
                  'rev.${u.dictionary.revision} → rev.${u.latestRevision}',
                ),
              ),
            if (res.failures.isNotEmpty)
              Text('Could not check: ${res.failures.keys.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final u in res.updates) {
                ref
                    .read(jobsProvider.notifier)
                    .start(
                      'update:${u.dictionary.id}',
                      ref.read(installerProvider).install(u.downloadUrl),
                    );
              }
            },
            child: Text('Update ${res.updates.length}'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      'Delete all dictionaries?',
      'This removes every installed dictionary.',
    );
    if (ok) await ref.read(repoProvider).deleteAll();
  }
}

class _DictTile extends ConsumerWidget {
  const _DictTile(this.d, this.index, this.count, this.updateJob);
  final Dictionary d;
  final int index;
  final int count;
  final Job? updateJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    final key = 'update:${d.id}';
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          leading: CircleAvatar(
            radius: 14,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(d.title),
          subtitle: Text('rev.${d.revision}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: d.enabled,
                onChanged: (v) => repo.setEnabled(d.id, v),
              ),
              // Side by side: stacked, the two buttons overflowed the row height.
              _TinyIcon(
                Icons.keyboard_arrow_up,
                'Move up',
                index == 0 ? null : () => repo.move(d.id, -1),
              ),
              _TinyIcon(
                Icons.keyboard_arrow_down,
                'Move down',
                index == count - 1 ? null : () => repo.move(d.id, 1),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'details') _details(context, d);
                  if (v == 'delete' &&
                      await _confirm(
                        context,
                        'Delete ${d.title}?',
                        'rev.${d.revision}',
                      )) {
                    await repo.delete(d.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'details', child: Text('Details')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
        if (updateJob != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: updateJob!.error != null
                ? _ErrorLine(
                    'Update failed: ${updateJob!.error}',
                    onClose: () => ref.read(jobsProvider.notifier).clear(key),
                  )
                : JobProgress(
                    updateJob!,
                    onCancel: () => ref.read(jobsProvider.notifier).cancel(key),
                  ),
          ),
      ],
    );
  }

  void _details(BuildContext context, Dictionary d) {
    final rows = {
      'Title': d.title,
      'Revision': d.revision,
      'Format': '${d.format}',
      'Author': d.author,
      'Description': d.description,
      'Attribution': d.attribution,
      'Updatable': d.isUpdatable ? 'Yes' : 'No',
      'Index URL': d.indexUrl,
      'Download URL': d.downloadUrl,
    };
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(:key, :value) in rows.entries)
                if (value != null && value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SelectableText.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$key\n',
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                          TextSpan(text: value),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon(this.icon, this.tooltip, this.onPressed);
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 32, minHeight: 24),
    padding: EdgeInsets.zero,
  );
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message, {required this.onClose});
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
      const SizedBox(width: 8),
      Expanded(child: Text(message)),
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Dismiss',
        onPressed: onClose,
      ),
    ],
  );
}

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
