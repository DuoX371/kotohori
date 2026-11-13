import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// A WebView shown with Android's hybrid composition. The default (drawing
/// into a texture) stays blank white on some GPUs, e.g. Huawei's Mali.
Widget appWebView(WebViewController controller) {
  final platform = controller.platform;
  return WebViewWidget.fromPlatformCreationParams(
    params: platform is AndroidWebViewController
        ? AndroidWebViewWidgetCreationParams(
            controller: platform,
            displayWithHybridComposition: true,
          )
        : PlatformWebViewWidgetCreationParams(controller: platform),
  );
}
