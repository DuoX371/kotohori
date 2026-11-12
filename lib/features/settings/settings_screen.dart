import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../anki/anki_settings_screen.dart';
import '../dictionary/ui/installed_screen.dart';
import '../dictionary/ui/recommended_screen.dart';
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
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Match system'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.single),
                ),
              ),
            ],
          ),
          Section(
            title: 'About',
            children: [
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
}
