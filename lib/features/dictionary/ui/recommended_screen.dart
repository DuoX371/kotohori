import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors.dart';
import '../catalog/catalog.dart';
import '../catalog/installer.dart';
import '../../../app/theme.dart';
import 'job_progress.dart';
import 'providers.dart';

class RecommendedScreen extends ConsumerWidget {
  const RecommendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final url = ref.watch(catalogUrlProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended dictionaries'),
        actions: [
          IconButton(
            tooltip: 'Catalog source',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _editUrl(context, ref, url),
          ),
        ],
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load catalog: $e')),
        data: (c) => RefreshIndicator(
          onRefresh: () => ref.refresh(catalogProvider.future),
          child: ListView(
            padding: pagePadding(context, top: 0),
            children: [
              if (c.fromFallback && url.isNotEmpty)
                const ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text(
                    'Showing the bundled catalog; the remote catalog could not be loaded.',
                  ),
                ),
              for (final g in c.$1.groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  child: Text(
                    g.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                for (final item in g.items) _CatalogTile(item),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editUrl(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final ctrl = TextEditingController(text: current);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catalog URL'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://…/catalog.json',
            helperText: 'Empty = bundled catalog',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != null) await ref.read(catalogUrlProvider.notifier).set(saved);
  }
}

class _CatalogTile extends ConsumerWidget {
  const _CatalogTile(this.item);
  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobsProvider)[item.id];
    final installedTitles =
        ref.watch(installedProvider).value?.map((d) => d.title).toSet() ??
        const {};
    final recorded = ref.watch(catalogInstallsProvider)[item.id];
    final installed = recorded != null && installedTitles.contains(recorded);
    final homepage = item.homepage;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (installed)
                  const Chip(
                    avatar: Icon(Icons.check, size: 16),
                    label: Text('Installed'),
                  )
                else if (job?.running != true)
                  FilledButton.tonal(
                    onPressed: () => _download(ref),
                    child: Text(job?.error != null ? 'Retry' : 'Download'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.description),
            if (homepage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => launchUrl(
                    Uri.parse(homepage),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Homepage'),
                ),
              ),
            if (job != null && job.running)
              JobProgress(
                job,
                onCancel: () => ref.read(jobsProvider.notifier).cancel(item.id),
              )
            else if (job?.error != null)
              Text(
                '${job!.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(WidgetRef ref) async {
    final job = await ref
        .read(jobsProvider.notifier)
        .start(item.id, ref.read(installerProvider).install(item.downloadUrl));
    final title = switch ((job.state, job.error)) {
      (Installed(:final result), _) => result.title,
      (_, DuplicateDictionaryException(:final title)) => title,
      _ => null,
    };
    if (title != null) {
      await ref.read(catalogInstallsProvider.notifier).record(item.id, title);
      ref.read(jobsProvider.notifier).clear(item.id);
    }
  }
}
