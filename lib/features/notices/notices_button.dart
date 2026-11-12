import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../anki/anki_providers.dart';
import '../anki/anki_settings_screen.dart';
import '../dictionary/ui/recommended_screen.dart';
import '../update/update_check.dart';
import 'notices.dart';

/// Bell in the app bar, with a count of open notices; opens them in a sheet.
class NoticesButton extends ConsumerWidget {
  const NoticesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(noticesProvider).length;
    return IconButton(
      tooltip: count == 0 ? 'Notifications' : '$count notifications',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(
          count > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_outlined,
        ),
      ),
      onPressed: () {
        ref.invalidate(ankiStatusProvider); // may have changed in AnkiDroid
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _NoticesSheet(),
        );
      },
    );
  }
}

class _NoticesSheet extends ConsumerWidget {
  const _NoticesSheet();

  Future<void> _act(BuildContext context, WidgetRef ref, Notice n) async {
    final nav = Navigator.of(context);
    void open(Widget screen) {
      nav.pop();
      nav.push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    switch (n.kind) {
      case NoticeKind.update:
        final r = ref.read(availableUpdateProvider);
        if (r != null) {
          await launchUrl(
            Uri.parse(r.url),
            mode: LaunchMode.externalApplication,
          );
        }
      case NoticeKind.dictionary:
        open(const RecommendedScreen());
      case NoticeKind.ankiMissing:
        await launchUrl(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.ichi2.anki',
          ),
          mode: LaunchMode.externalApplication,
        );
      case NoticeKind.ankiPermission:
        await ref.read(ankiBridgeProvider).requestPermission();
        ref.invalidate(ankiStatusProvider);
      case NoticeKind.ankiSetup:
        open(const AnkiSettingsScreen());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    final t = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Notifications', style: t.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (notices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "You're all set. Nothing needs your attention.",
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final n in notices)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(n.icon, color: t.colorScheme.primary),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: t.textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.body,
                                    style: t.textTheme.bodyMedium?.copyWith(
                                      color: t.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (n.dismissKey case final key?)
                              TextButton(
                                onPressed: () => ref
                                    .read(dismissedNoticesProvider.notifier)
                                    .dismiss(key),
                                child: Text(
                                  n.kind == NoticeKind.update
                                      ? 'Later'
                                      : 'Dismiss',
                                ),
                              ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _act(context, ref, n),
                              child: Text(n.action),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
