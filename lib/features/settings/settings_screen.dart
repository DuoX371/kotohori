import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../anki/anki_settings_screen.dart';
import '../dictionary/ui/installed_screen.dart';
import '../dictionary/ui/recommended_screen.dart';
import '../update/update_check.dart';
import '../update/update_snack.dart';
import 'appearance_settings.dart';
import 'subtitle_style_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));
    Widget link(IconData icon, String title, String subtitle, Widget screen) =>
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(screen),
        );
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: pagePadding(context, top: 0),
        children: [
          // Grouped like the app's tabs: Player, Reader, Dictionary; then shared settings.
          Section(
            title: 'Dictionaries',
            children: [
              link(
                Icons.library_books_outlined,
                'Installed dictionaries',
                'Turn on or off, reorder, import, update',
                const InstalledScreen(),
              ),
              link(
                Icons.download_outlined,
                'Get dictionaries',
                'Download recommended ones in one tap',
                const RecommendedScreen(),
              ),
            ],
          ),
          Section(
            title: 'Flashcards',
            children: [
              link(
                Icons.style_outlined,
                'Anki',
                'Deck, note type, fields, screenshot and audio',
                const AnkiSettingsScreen(),
              ),
            ],
          ),
          Section(
            title: 'Player',
            children: [
              link(
                Icons.closed_caption_outlined,
                'Subtitle appearance',
                'Size, colour, outline or box',
                const SubtitleStyleScreen(),
              ),
            ],
          ),
          const Section(
            title: 'Reader',
            children: [
              ListTile(
                enabled: false,
                leading: Icon(Icons.menu_book_outlined),
                title: Text('Light novel reader'),
                subtitle: Text('Coming soon'),
              ),
            ],
          ),
          Section(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                // Phones: full width, no icons, so "System" doesn't wrap.
                child: LayoutBuilder(
                  builder: (context, box) {
                    final icons = box.maxWidth >= 400;
                    return SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      expandedInsets: icons ? null : EdgeInsets.zero,
                      segments: [
                        for (final (value, icon, label) in const [
                          (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
                          (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
                          (
                            ThemeMode.system,
                            Icons.brightness_auto_outlined,
                            'System',
                          ),
                        ])
                          ButtonSegment(
                            value: value,
                            icon: icons ? Icon(icon) : null,
                            label: Text(label, maxLines: 1, softWrap: false),
                          ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) =>
                          ref.read(themeModeProvider.notifier).set(s.single),
                    );
                  },
                ),
              ),
            ],
          ),
          Section(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: const Text('Check for updates'),
                subtitle: Text(
                  'Version ${ref.watch(appVersionProvider).value ?? '…'}',
                ),
                onTap: () => _checkForUpdates(context, ref),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.update),
                title: const Text('Check when Kotohori starts'),
                subtitle: const Text('Asks GitHub for the latest release'),
                value: ref.watch(checkOnLaunchProvider),
                onChanged: ref.read(checkOnLaunchProvider.notifier).set,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Kotohori',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(appIconAsset, width: 64, height: 64),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Checking for updates…')),
    );
    try {
      final r = await ref.read(updateCheckProvider)();
      messenger.hideCurrentSnackBar();
      if (!context.mounted) return;
      if (r != null) {
        ref.read(availableUpdateProvider.notifier).set(r);
        showUpdateSnack(context, r);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("You're on the latest version")),
        );
      }
    } on Object catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't check for updates. Are you online?"),
          ),
        );
    }
  }
}
