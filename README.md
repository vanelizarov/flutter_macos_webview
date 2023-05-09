# flutter_macos_webview

Flutter plugin that lets you display native WebView on macOS

For docs see [flutter_macos_webview.dart](https://github.com/vanelizarov/flutter_macos_webview/blob/master/lib/flutter_macos_webview.dart)

> :warning: Right as of now, InApp WebView is not supported as PlatformView for Desktop is not in the stable phase.

How to use:
1. Add the plugin to `pubspec.yaml`

```
flutter pub add flutter_macos_webview
```

or

```
dependencies:
  flutter:
    sdk: flutter

  flutter_macos_webview:
  ```

2. Import the dart file wherever you are implementing it.
```
import 'package:flutter_macos_webview/flutter_macos_webview.dart';
```

3. There are only 2 ways to call the webview as of now.
  - Sheet
  - Modal
```
CupertinoButton(
  child: const Text('Open as modal'),
  onPressed: () => _onOpenPressed(PresentationStyle.modal),
),
CupertinoButton(
  child: const Text('Open as modal'),
  onPressed: () => _onOpenPressed(PresentationStyle.sheet),
)
```

Where `_onOpenPressed` is defined as below:

```
Future<void> _onOpenPressed(PresentationStyle presentationStyle) async {
    final webview = FlutterMacOSWebView(
      onOpen: () => print('Opened'),
      onClose: () => print('Closed'),
      onPageStarted: (url) => print('Page started: $url'),
      onPageFinished: (url) => print('Page finished: $url'),
      onWebResourceError: (err) {
        print(
          'Error: ${err.errorCode}, ${err.errorType}, ${err.domain}, ${err.description}',
        );
      },
    );

    await webview.open(
      url: 'https://www.flutter.dev/',
      presentationStyle: presentationStyle,
      size: const Size(720.0, 720.0),
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    );

  }
```
