import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/anki_bridge.dart';
import '../../platform/media_tools.dart';
import '../dictionary/ui/providers.dart' show appPathsProvider, dioProvider;
import 'card_exporter.dart';

final ankiBridgeProvider = Provider<AnkiBridge>(
  (_) => MethodChannelAnkiBridge(),
);
final mediaToolsProvider = Provider<MediaTools>(
  (_) => MethodChannelMediaTools(),
);
final cardExporterProvider = Provider(
  (ref) => CardExporter(
    anki: ref.watch(ankiBridgeProvider),
    media: ref.watch(mediaToolsProvider),
    tempDir: ref.watch(appPathsProvider).tempDir,
    dio: ref.watch(dioProvider),
  ),
);
