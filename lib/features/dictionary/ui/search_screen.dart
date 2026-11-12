import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../settings/settings_screen.dart';
import '../lookup/lookup.dart';
import 'providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  // JavaScript stays disabled (default): the page is static HTML built from dictionary data.
  final _web = WebViewController();
  var _matched = 0;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _web.loadHtmlString(
      ref
          .read(htmlBuilderProvider)
          .page(
            LookupResult.empty,
            emptyMessage: 'Type Japanese text to look up',
          ),
    );
  }

  Future<void> _search(String q) async {
    final result = await ref.read(lookupProvider).lookup(q, 0);
    if (!mounted) return;
    setState(() {
      _query = q;
      _matched = result.matchedLength;
    });
    await _web.loadHtmlString(ref.read(htmlBuilderProvider).page(result));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
        actions: [
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
              child: WebViewWidget(controller: _web),
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
