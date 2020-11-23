import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/services.dart';

const _kChannel = 'com.vanelizarov.flutter_macos_webview/method';

class FlutterMacosWebview {
  FlutterMacosWebview({
    this.onLaunch,
    this.onClose,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
  }) : _channel = MethodChannel(_kChannel) {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final MethodChannel _channel;

  final void Function() onLaunch;
  final void Function() onClose;
  final void Function(String url) onPageStarted;
  final void Function(String url) onPageFinished;
  final void Function(WebResourceError error) onWebResourceError;

  Future<void> launch({@required String url}) async {
    await _channel.invokeMethod('launch', {'url': url});
  }

  Future<void> close() async {
    await _channel.invokeMethod('close');
  }

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLaunch':
        onLaunch?.call();
        return;
      case 'onClose':
        onClose?.call();
        return;
      case 'onPageStarted':
        onPageStarted?.call(call.arguments['url']);
        return;
      case 'onPageFinished':
        onPageFinished?.call(call.arguments['url']);
        return;
      case 'onWebResourceError':
        onWebResourceError?.call(
          WebResourceError(
            errorCode: call.arguments['errorCode'],
            description: call.arguments['description'],
            domain: call.arguments['domain'],
            errorType: call.arguments['errorType'] == null
                ? null
                : WebResourceErrorType.values.firstWhere(
                    (type) {
                      return type.toString() ==
                          '$WebResourceErrorType.${call.arguments['errorType']}';
                    },
                  ),
          ),
        );
        return;
    }
  }
}

class WebResourceError {
  WebResourceError({
    @required this.errorCode,
    @required this.description,
    this.domain,
    this.errorType,
  })  : assert(errorCode != null),
        assert(description != null);

  final int errorCode;
  final String description;
  final String domain;
  final WebResourceErrorType errorType;
}

enum WebResourceErrorType {
  unknown,
  webContentProcessTerminated,
  webViewInvalidated,
  javaScriptExceptionOccurred,
  javaScriptResultTypeIsUnsupported,
}
