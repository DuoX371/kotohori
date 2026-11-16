import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../explain/explain_session.dart';
import '../explain/explain_settings.dart';
import '../explain/explain_tidy.dart';
import '../explain/gemini_client.dart';
import 'player_controller.dart';

/// The AI explanation of a subtitle line, docked where the dictionary popup goes.
class ExplainPanel extends StatelessWidget {
  const ExplainPanel(this.c, {super.key, required this.onOpenSettings});
  final PlayerController c;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: c.explain,
        builder: (context, _) {
          final s = c.explain;
          final r = s.request;
          // Closing: keep the frame empty while the panel slides away.
          if (r == null) return const SizedBox.expand();
          // Like the settings pages' section titles.
          final heading = t.textTheme.titleSmall?.copyWith(
            color: t.colorScheme.primary,
          );
          final busy =
              s.status == ExplainStatus.waiting ||
              s.status == ExplainStatus.writing;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: t.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Explain', style: t.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        geminiModelFor(r.model).label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ask again',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: busy ? null : s.regenerate,
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: c.closeExplain,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SelectionArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.targetText,
                          style: t.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (s.status == ExplainStatus.waiting)
                        Row(
                          children: [
                            const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Thinking…', style: t.textTheme.bodyMedium),
                          ],
                        ),
                      if (s.text.isNotEmpty)
                        // The package's own heading styles ignore the app
                        // theme (dark on dark here), so set them.
                        GptMarkdownTheme(
                          gptThemeData: GptMarkdownThemeData(
                            brightness: t.brightness,
                            h1: heading,
                            h2: heading,
                            h3: heading,
                          ),
                          child: GptMarkdown(
                            tidyExplanation(s.text),
                            style: t.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      if (s.error case final e?) ...[
                        if (s.text.isNotEmpty) const SizedBox(height: 12),
                        _Failure(
                          e,
                          cutOff: s.text.isNotEmpty,
                          onRetry: s.regenerate,
                          onOpenSettings: onOpenSettings,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure(
    this.error, {
    required this.cutOff,
    required this.onRetry,
    required this.onOpenSettings,
  });
  final ExplainException error;

  /// Part of an answer arrived before it failed.
  final bool cutOff;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final settings = const {
      ExplainError.badKey,
      ExplainError.limit,
      ExplainError.noModel,
    }.contains(error.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${cutOff ? 'The answer stopped early. ' : ''}'
          '${explainErrorMessage(error)}',
          style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.error),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
            if (settings)
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Open settings'),
              ),
          ],
        ),
      ],
    );
  }
}
