import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../dictionary/ui/providers.dart' show appPathsProvider;

const _app = MethodChannel('kotohori/app');

/// A book's picture full screen: pinch to zoom, tap to close, hold for
/// Save / Share / Copy.
class ImageViewer extends ConsumerWidget {
  const ImageViewer({super.key, required this.path});

  final String path;

  static Route<void> route(String path) => PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => ImageViewer(path: path),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ModalRoute.of(context)?.animation;
    Widget picture = Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
      ),
    );
    if (shown != null) {
      picture = ScaleTransition(
        scale: Tween(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(parent: shown, curve: Curves.easeOutCubic)),
        child: picture,
      );
    }
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        onLongPress: () => _menu(context, ref),
        child: InteractiveViewer(
          maxScale: 6,
          child: SizedBox.expand(
            child: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: picture),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (id, icon, label) in const [
              ('save', Icons.download, 'Save to Pictures'),
              ('share', Icons.share, 'Share'),
              ('copy', Icons.copy, 'Copy'),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(context).pop(id),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));
    try {
      switch (choice) {
        case 'save':
          final saved = await _app.invokeMethod<bool>('saveImage', {
            'path': path,
          });
          say(
            saved == true
                ? 'Saved to Pictures/Kotohori'
                : 'Saving needs Android 10 or newer. Use Share instead.',
          );
        case 'share':
          await _app.invokeMethod<void>('shareImage', {
            'path': shareableCopy(path, ref.read(appPathsProvider).tempDir),
          });
        case 'copy':
          final systemShows = await _app.invokeMethod<bool>('copyImage', {
            'path': shareableCopy(path, ref.read(appPathsProvider).tempDir),
          });
          if (systemShows != true) say('Picture copied');
      }
    } on PlatformException catch (e) {
      say(
        "Couldn't ${choice == 'save' ? 'save' : choice} the picture: ${e.message}",
      );
    }
  }
}

String shareableCopy(String path, String tempDir) {
  final dir = Directory(p.join(tempDir, 'shared'));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  return File(path).copySync(p.join(dir.path, p.basename(path))).path;
}

/// Starts a system drag of the picture other apps can take; only while the
/// finger is still down.
Future<void> dragPicture(String path, String tempDir) => _app
    .invokeMethod<void>('dragImage', {'path': shareableCopy(path, tempDir)})
    .catchError((Object _) {});
