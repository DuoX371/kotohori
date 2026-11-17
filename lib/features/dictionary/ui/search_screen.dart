import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../platform/web_view.dart';

import '../../settings/settings_screen.dart';
import '../lookup/lookup.dart';
import '../render/dictionary_link.dart';
import 'providers.dart';
import '../../notices/notices_button.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  // JavaScript stays disabled (default): the page is static HTML built from dictionary data.
  late final _web = WebViewController()
    ..setNavigationDelegate(
      NavigationDelegate(
        // Only pages we build are shown: a followed link would go blank.
        onNavigationRequest: (request) {
          final link = dictionaryLink(request.url);
          if (link.query case final text?) {
            _text.text = text;
            _search(text);
          } else if (isOwnPage(request.url)) {
            return NavigationDecision.navigate;
          } else if (link.web case final uri?) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return NavigationDecision.prevent;
        },
      ),
    );
  var _matched = 0;
  var _query = '';

  LookupResult? _result;
  bool? _drawnDark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark != _drawnDark) _draw(dark);
  }

  Future<void> _draw(bool dark) {
    _drawnDark = dark;
    return _web.loadHtmlString(
      ref
          .read(htmlBuilderProvider)
          .page(
            _result ?? LookupResult.empty,
            emptyMessage: _result == null
                ? 'Type Japanese text to look up'
                : ref.read(emptyLookupMessageProvider),
            dark: dark,
          ),
      baseUrl: dictionaryPageBase,
    );
  }

  Future<void> _search(String q) async {
    final result = await ref.read(lookupProvider).lookup(q, 0);
    if (!mounted) return;
    setState(() {
      _query = q;
      _matched = result.matchedLength;
      _result = result;
    });
    await _draw(Theme.of(context).brightness == Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(emptyLookupMessageProvider); // keeps the dictionary list loaded
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
        actions: [
          const NoticesButton(),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _text,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: '食べなかった',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _search(_text.text),
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 18),
                    children: [
                      TextSpan(
                        text: _query.substring(0, _matched),
                        style: TextStyle(
                          backgroundColor: scheme.primaryContainer,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      TextSpan(text: _query.substring(_matched)),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              top: false,
              child: appWebView(_web),
            ), // clear the nav bar / taskbar
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}
