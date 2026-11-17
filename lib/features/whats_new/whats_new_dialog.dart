import 'package:flutter/material.dart';

import 'changelog.dart';

/// The popup shown once after an update: what changed in [releases] (newest
/// first; more than one when versions were skipped). Closes on "Got it" or a
/// tap outside.
Future<void> showWhatsNew(
  BuildContext context,
  List<ChangelogRelease> releases,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const Icon(Icons.auto_awesome_outlined),
    title: Text("What's new in ${releases.first.version}"),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, r) in releases.indexed) ...[
              if (i > 0) const Divider(height: 28),
              // The newest version is named in the title already.
              _Release(r, showVersion: i > 0),
            ],
          ],
        ),
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Got it'),
      ),
    ],
  ),
);

class _Release extends StatelessWidget {
  const _Release(this.release, {required this.showVersion});
  final ChangelogRelease release;
  final bool showVersion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showVersion)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Version ${release.version}',
              style: t.textTheme.titleSmall,
            ),
          ),
        for (final (i, g) in release.groups.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(
            g.title,
            style: t.textTheme.labelLarge?.copyWith(
              color: t.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in g.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: t.textTheme.bodyMedium),
                  Expanded(child: Text(item, style: t.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
