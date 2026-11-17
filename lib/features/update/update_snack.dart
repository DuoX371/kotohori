import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_check.dart';

Future<void> showUpdateDialog(BuildContext context, AppRelease r) async {
  final update = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.system_update_outlined),
      title: Text('Kotohori ${r.version} is available'),
      content: const Text('A newer version is ready to download.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Update now'),
        ),
      ],
    ),
  );
  if (update == true) {
    await launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication);
  }
}

void showUpdateSnack(BuildContext context, AppRelease r) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Kotohori ${r.version} is available'),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'Download',
        onPressed: () =>
            launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication),
      ),
    ),
  );
}
