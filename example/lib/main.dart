import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_macos_webview/flutter_macos_webview.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  Future<void> _onOpenPressed(PresentationStyle presentationStyle) async {
    final webview = FlutterMacOSWebView(
      onOpen: () => print('Opened'),
      onClose: (url) => print('Closed $url'),
      onSetUrl: (url) => print('Set url $url'),
      onPageStarted: (url) => print('Page started: $url'),
      onPageFinished: (url) => print('Page finished: $url'),
      onWebResourceError: (err) {
        print(
          'Error: ${err.errorCode}, ${err.errorType}, ${err.domain}, ${err.description}',
        );
      },
    );

    await webview.open(
      url: 'https://google.com',
      presentationStyle: presentationStyle,
      size: Size(400.0, 400.0),
      userAgent:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    );

    // Timer.periodic(Duration(seconds: 3), (t) async {
    //   print(await webview.getCurrentUrl());
    // });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            child: Text('Open as modal'),
            onPressed: () => _onOpenPressed(PresentationStyle.modal),
          ),
          SizedBox(height: 16.0),
          CupertinoButton(
            child: Text('Open as sheet'),
            onPressed: () => _onOpenPressed(PresentationStyle.sheet),
          ),
        ],
      ),
    );
  }
}
