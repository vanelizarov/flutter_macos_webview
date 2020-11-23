//
//  WebViewController.swift
//  flutter_macos_webview
//
//  Created by vanya elizarov on 22.11.2020.
//

import Cocoa
import FlutterMacOS
import WebKit

class WebViewController: NSViewController {
    private let webview: WKWebView
    private let channel: FlutterMethodChannel
        
    required init(channel: FlutterMethodChannel, frame: NSRect) {
        self.channel = channel
        
        webview = WKWebView(frame: frame)
        webview.configuration.preferences.javaScriptEnabled = true
        
        super.init(nibName: nil, bundle: nil)
        
        webview.navigationDelegate = self
        webview.uiDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadUrl(url: URL) {
        let req = URLRequest(url: url)
        webview.load(req)
    }
    
    override func loadView() {
        self.view = webview
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
}

extension WebViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        channel.invokeMethod("onClose", arguments: nil)
    }
}

extension WebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let isMainFrame = navigationAction.targetFrame?.isMainFrame else { return nil }
        if !isMainFrame {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        channel.invokeMethod("onPageStarted", arguments: [ "url": url ])
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        channel.invokeMethod("onPageFinished", arguments: [ "url": url ])
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let error = NSError(
            domain: WKError.errorDomain,
            code: WKError.webContentProcessTerminated.rawValue,
            userInfo: nil
        )
        onWebResourceError(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onWebResourceError(error as NSError)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onWebResourceError(error as NSError)
    }
    
    static func errorCodeToString(code: Int) -> String? {
        switch code {
            case WKError.unknown.rawValue:
                return "unknown";
            case WKError.webContentProcessTerminated.rawValue:
                return "webContentProcessTerminated";
            case WKError.webViewInvalidated.rawValue:
                return "webViewInvalidated";
            case WKError.javaScriptExceptionOccurred.rawValue:
                return "javaScriptExceptionOccurred";
            case WKError.javaScriptResultTypeIsUnsupported.rawValue:
                return "javaScriptResultTypeIsUnsupported";
            default:
                return nil;
        }
        
    }
    
    func onWebResourceError(_ error: NSError) {
        channel.invokeMethod("onWebResourceError", arguments: [
            "errorCode": error.code,
            "domain": error.domain,
            "description": error.description,
            "errorType": WebViewController.errorCodeToString(code: error.code) as Any
        ])
    }
}

