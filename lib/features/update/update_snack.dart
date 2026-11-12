import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_check.dart';

/// "Kotohori 0.2.0 is available" with a button to its release page.
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
