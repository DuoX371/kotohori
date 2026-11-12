import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../player/subtitle_overlay.dart';
import 'subtitle_style.dart';

/// Settings → Subtitles: size, colour, weight and backdrop, with a live preview.
class SubtitleStyleScreen extends ConsumerWidget {
  const SubtitleStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(subtitleStyleProvider);
    final n = ref.read(subtitleStyleProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitles'),
        actions: [
          TextButton(
            onPressed: s == const SubtitleStyle()
                ? null
                : () => n.update((_) => const SubtitleStyle()),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: pagePadding(context, top: 8),
        children: [
          const _Preview(),
          Section(
            title: 'Text',
            children: [
              ListTile(
                title: const Text('Size'),
                subtitle: Slider(
                  value: s.size,
                  min: SubtitleStyle.minSize,
                  max: SubtitleStyle.maxSize,
                  divisions:
                      ((SubtitleStyle.maxSize - SubtitleStyle.minSize) / 2)
                          .round(),
                  label: s.size.round().toString(),
                  onChanged: (v) => n.update((x) => x.copyWith(size: v)),
                ),
                trailing: Text('${s.size.round()}'),
              ),
              ListTile(
                title: const Text('Colour'),
                trailing: SegmentedButton<Color>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: SubtitleStyle.white,
                      label: Text('White'),
                    ),
                    ButtonSegment(
                      value: SubtitleStyle.yellow,
                      label: Text('Yellow'),
                    ),
                  ],
                  selected: {s.color},
                  onSelectionChanged: (v) =>
                      n.update((x) => x.copyWith(color: v.single)),
                ),
              ),
              SwitchListTile(
                title: const Text('Bold'),
                value: s.bold,
                onChanged: (v) => n.update((x) => x.copyWith(bold: v)),
              ),
            ],
          ),
          Section(
            title: 'Background',
            footer: 'What keeps the text readable on bright scenes.',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<SubtitleBackdrop>(
                  showSelectedIcon: false,
                  segments: [
                    for (final b in SubtitleBackdrop.values)
                      ButtonSegment(value: b, label: Text(b.label)),
                  ],
                  selected: {s.backdrop},
                  onSelectionChanged: (v) =>
                      n.update((x) => x.copyWith(backdrop: v.single)),
                ),
              ),
              if (s.backdrop == SubtitleBackdrop.box)
                ListTile(
                  title: const Text('Box darkness'),
                  subtitle: Slider(
                    value: s.boxOpacity,
                    min: 0.1,
                    max: 0.9,
                    divisions: 8,
                    label: '${(s.boxOpacity * 100).round()}%',
                    onChanged: (v) =>
                        n.update((x) => x.copyWith(boxOpacity: v)),
                  ),
                  trailing: Text('${(s.boxOpacity * 100).round()}%'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A bright, busy "frame": the hard case for readability.
class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(subtitleStyleProvider);
    return Card(
      child: AspectRatio(
        aspectRatio: 21 / 9,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFBFD8EE), Color(0xFFF2E6C9), Color(0xFF8A9A6B)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SubtitleText(
                'スバルのことも守ってあげなくちゃ。',
                style: s,
                highlight: const (7, 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
