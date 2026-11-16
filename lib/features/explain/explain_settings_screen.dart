import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import 'explain_settings.dart';
import 'gemini_client.dart';

/// Settings → AI explain: turn it on and paste a Gemini API key.
class ExplainSettingsScreen extends ConsumerStatefulWidget {
  const ExplainSettingsScreen({super.key});

  @override
  ConsumerState<ExplainSettingsScreen> createState() => _State();
}

class _State extends ConsumerState<ExplainSettingsScreen> {
  final _key = TextEditingController();
  var _keyLoaded = false;
  var _showKey = false;

  /// Null: not run. Otherwise the result line and whether it passed.
  (String, bool)? _test;
  var _testing = false;

  @override
  void initState() {
    super.initState();
    ref.read(explainApiKeyProvider.future).then((k) {
      if (!mounted) return;
      _key.text = k;
      setState(() => _keyLoaded = true);
    });
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  void _setKey(String value) {
    setState(() => _test = null);
    ref.read(explainApiKeyProvider.notifier).set(value);
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) return;
    _key.text = text;
    _setKey(text);
  }

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _test = null;
    });
    (String, bool) result;
    try {
      final key = await ref.read(explainApiKeyProvider.future);
      final problem = explainSetupProblem(apiKey: key);
      if (problem != null) throw ExplainException(ExplainError.other, problem);
      final client = await ref.read(
        geminiClientProvider(ref.read(explainModelProvider)).future,
      );
      await client.checkKey();
      await ref.read(explainKeyTestedProvider.notifier).passed(key);
      result = ('Working', true);
    } on ExplainException catch (e) {
      result = (explainErrorMessage(e), false);
    } on Object {
      result = ('Something went wrong.', false);
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _test = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final model = ref.watch(explainModelProvider);
    final tested = ref.watch(explainKeyTestedProvider);
    // A pass from an earlier visit still shows as passed.
    final test = _test ?? (tested ? ('Working', true) : null);
    final muted = t.textTheme.bodyMedium?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('AI explain')),
      body: ListView(
        padding: pagePadding(context, top: 0),
        children: [
          Section(
            title: 'Explain',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Turn on Explain'),
                subtitle: Text(
                  tested
                      ? 'Adds a ✨ button to the player'
                      : 'Test your key below first',
                ),
                value: ref.watch(explainEnabledProvider),
                onChanged: tested
                    ? ref.read(explainEnabledProvider.notifier).set
                    : null,
              ),
            ],
          ),
          Section(
            title: 'API key',
            footer:
                'Stored encrypted on this device. On the free plan, Google '
                'may use what you send to improve its products.',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: TextField(
                  controller: _key,
                  enabled: _keyLoaded,
                  obscureText: !_showKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: _setKey,
                  decoration: InputDecoration(
                    labelText: 'Gemini API key',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _showKey ? 'Hide key' : 'Show key',
                          icon: Icon(
                            _showKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _showKey = !_showKey),
                        ),
                        IconButton(
                          tooltip: 'Paste',
                          icon: const Icon(Icons.content_paste_rounded),
                          onPressed: _paste,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                // Section centres its rows; the guide reads from the left.
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to get a key', style: t.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final (i, step) in const [
                      'Open Google AI Studio and sign in with your Google account.',
                      'Tap "Create API key" and follow the steps.',
                      'Copy the key, come back here and tap the paste button above.',
                    ].indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${i + 1}. $step', style: muted),
                      ),
                    const SizedBox(height: 4),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open Google AI Studio'),
                      onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: _testing
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        switch (test) {
                          (_, true) => Icons.check_circle_outline_rounded,
                          (_, false) => Icons.error_outline_rounded,
                          null => Icons.wifi_tethering_rounded,
                        },
                        color: switch (test) {
                          (_, true) => Colors.green,
                          (_, false) => t.colorScheme.error,
                          null => null,
                        },
                      ),
                title: const Text('Test your key'),
                subtitle: Text(
                  _testing
                      ? 'Checking with Google…'
                      : test?.$1 ?? 'Checks your key and model',
                ),
                onTap: _testing ? null : _runTest,
              ),
            ],
          ),
          Section(
            title: 'Model',
            children: [
              for (final m in geminiModels)
                ListTile(
                  leading: Icon(
                    m.id == model
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: m.id == model ? t.colorScheme.primary : null,
                  ),
                  title: Text(m.label),
                  subtitle: Text(m.summary),
                  selected: m.id == model,
                  onTap: () {
                    setState(() => _test = null);
                    ref.read(explainModelProvider.notifier).set(m.id);
                  },
                ),
            ],
          ),
          // A link, not a row in the card: there it read as a fifth model.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('See your usage in Google AI Studio'),
              onPressed: () => launchUrl(
                Uri.parse('https://aistudio.google.com/rate-limit'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
