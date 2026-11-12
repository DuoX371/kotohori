import 'package:flutter/material.dart';

import '../catalog/installer.dart';
import 'providers.dart';

/// Progress bar + status line for a download/import job.
class JobProgress extends StatelessWidget {
  const JobProgress(this.job, {super.key, this.onCancel});
  final Job job;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final (label, value) = switch (job.state) {
      Downloading(:final received, :final total) => (
        'Downloading ${_mb(received)}${total > 0 ? ' / ${_mb(total)}' : ''}',
        total > 0 ? received / total : null,
      ),
      Importing(:final progress) => (progress.message, progress.fraction),
      Installed(:final result) => ('Installed ${result.title}', 1.0),
      null => ('Starting…', null),
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: value),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onCancel != null && job.running)
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
      ],
    );
  }
}

String _mb(int bytes) => '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
