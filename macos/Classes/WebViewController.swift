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
    enum PresentationStyle: Int {
        case modal = 0
        case sheet = 1
    }

    static let closeNotification = Notification.Name("WebViewCloseNotification")

    private let webview: WKWebView

    private let frame: CGRect
    private let channel: FlutterMethodChannel
    private let presentationStyle: PresentationStyle
    private let modalTitle: String!
    private let sheetCloseButtonTitle: String
    private let showSetUrlButton: Boolean

    var javascriptEnabled: Bool {
        set { webview.configuration.preferences.javaScriptEnabled = newValue }
        get { webview.configuration.preferences.javaScriptEnabled }
    }

    var userAgent: String? {
        set {
            if let userAgent = newValue {
                webview.customUserAgent = userAgent // " Custom Agent"
            } else {
                webview.customUserAgent = nil
            }
        }
        get { webview.customUserAgent }
    }

    required init(
        channel: FlutterMethodChannel,
        frame: NSRect,
        presentationStyle: PresentationStyle,
        modalTitle: String,
        sheetCloseButtonTitle: String,
        showSetUrlButton: Boolean
    ) {
        self.channel = channel
        self.frame = frame
        self.presentationStyle = presentationStyle
        self.modalTitle = modalTitle
        self.sheetCloseButtonTitle = sheetCloseButtonTitle
        self.showSetUrlButton = showSetUrlButton

        webview = WKWebView()

        super.init(nibName: nil, bundle: nil)

        webview.navigationDelegate = self
        webview.uiDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadUrl(url: URL) {
        let req = URLRequest(url: url)
        webview.load(req)
    }

    func currentUrl() -> String? {
        return webview.url?.absoluteString
    }

    @objc private func closeSheet() {
        view.window?.close()
    }

    @objc private func setUrl() {
        let url = webview.url?.absoluteString
        channel.invokeMethod("onSetUrl", arguments: ["url": url])
    }

    @objc private func goBack() {
        webview.goBack()
    }

    @objc private func goForward() {
        webview.goForward()
    }

    private func setupViews() {
        webview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webview)

        var constraints: [NSLayoutConstraint] = [
            webview.topAnchor.constraint(equalTo: view.topAnchor),
            webview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]

        if presentationStyle == .sheet {
            let bottomBarHeight: CGFloat = 44.0
            constraints.append(
                webview.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -bottomBarHeight)
            )

            let bottomBar = NSView()
            bottomBar.wantsLayer = true
            bottomBar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            bottomBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bottomBar)

            constraints.append(contentsOf: [
                bottomBar.topAnchor.constraint(equalTo: webview.bottomAnchor),
                bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomBar.heightAnchor.constraint(equalToConstant: bottomBarHeight),
            ])

            let closeButton = NSButton()
            closeButton.isBordered = false
            closeButton.title = sheetCloseButtonTitle
            closeButton.font = NSFont.systemFont(ofSize: 14.0)
            closeButton.contentTintColor = .systemRed
            closeButton.bezelStyle = .rounded
            closeButton.setButtonType(.momentaryChange)
            closeButton.sizeToFit()
            closeButton.target = self
            closeButton.action = #selector(closeSheet)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            bottomBar.addSubview(closeButton)

            let setUrlButton = NSButton()
            setUrlButton.isBordered = true
            setUrlButton.isHidden = showSetUrlButton
            setUrlButton.bezelColor = .systemBlue
            setUrlButton.title = "Set URL"
            setUrlButton.font = NSFont.systemFont(ofSize: 14.0)
            setUrlButton.bezelStyle = .rounded
            setUrlButton.setButtonType(.momentaryPushIn)
            setUrlButton.frame.size.width = 65.0
            setUrlButton.target = self
            setUrlButton.action = #selector(setUrl)
            setUrlButton.translatesAutoresizingMaskIntoConstraints = false
            bottomBar.addSubview(setUrlButton)

            let backButton = NSButton()
            backButton.isBordered = false
            backButton.title = "←"
            backButton.font = NSFont.systemFont(ofSize: 20.0, weight: NSFont.Weight.semibold)
            backButton.contentTintColor = .systemBlue
            backButton.bezelStyle = .rounded
            backButton.setButtonType(.momentaryChange)
            backButton.sizeToFit()
            backButton.target = self
            backButton.action = #selector(goBack)
            backButton.translatesAutoresizingMaskIntoConstraints = false
            bottomBar.addSubview(backButton)

            let forwardButton = NSButton()
            forwardButton.isBordered = false
            forwardButton.title = "→"
            forwardButton.font = NSFont.systemFont(ofSize: 20.0, weight: NSFont.Weight.semibold)
            forwardButton.contentTintColor = .systemBlue
            forwardButton.bezelStyle = .rounded
            forwardButton.setButtonType(.momentaryChange)
            forwardButton.sizeToFit()
            forwardButton.target = self
            forwardButton.action = #selector(goForward)
            forwardButton.translatesAutoresizingMaskIntoConstraints = false
            bottomBar.addSubview(forwardButton)

            constraints.append(contentsOf: [
                closeButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
                closeButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
                closeButton.widthAnchor.constraint(equalToConstant: closeButton.frame.width + 20.0),
                closeButton.heightAnchor.constraint(equalTo: bottomBar.heightAnchor),

                setUrlButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor),
                setUrlButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
                setUrlButton.widthAnchor.constraint(equalToConstant: setUrlButton.frame.width + 20.0),
                setUrlButton.heightAnchor.constraint(equalTo: bottomBar.heightAnchor),

                backButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
                backButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
                backButton.widthAnchor.constraint(equalToConstant: backButton.frame.width + 20.0),
                backButton.heightAnchor.constraint(equalTo: bottomBar.heightAnchor),

                forwardButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
                forwardButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
                forwardButton.widthAnchor.constraint(equalToConstant: forwardButton.frame.width + 20.0),
                forwardButton.heightAnchor.constraint(equalTo: bottomBar.heightAnchor),

            ])
        } else {
            title = modalTitle
            constraints.append(webview.heightAnchor.constraint(equalTo: view.heightAnchor))
        }

        constraints.forEach { c in
            c.isActive = true
        }
    }

    override func loadView() {
        view = NSView(frame: frame)
        view.translatesAutoresizingMaskIntoConstraints = false

        setupViews()
    }

    override func viewDidAppear() {
        view.window?.delegate = self
    }
}

extension WebViewController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        NotificationCenter.default.post(name: WebViewController.closeNotification, object: nil)
    }
}

extension WebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith _: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures _: WKWindowFeatures) -> WKWebView? {
        guard let isMainFrame = navigationAction.targetFrame?.isMainFrame else { return nil }
        if !isMainFrame {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        channel.invokeMethod("onPageStarted", arguments: ["url": url])
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        channel.invokeMethod("onPageFinished", arguments: ["url": url])
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        let error = NSError(
            domain: WKError.errorDomain,
            code: WKError.webContentProcessTerminated.rawValue,
            userInfo: nil
        )
        onWebResourceError(error)
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        onWebResourceError(error as NSError)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        onWebResourceError(error as NSError)
    }

    static func errorCodeToString(code: Int) -> String? {
        switch code {
        case WKError.unknown.rawValue:
            return "unknown"
        case WKError.webContentProcessTerminated.rawValue:
            return "webContentProcessTerminated"
        case WKError.webViewInvalidated.rawValue:
            return "webViewInvalidated"
        case WKError.javaScriptExceptionOccurred.rawValue:
            return "javaScriptExceptionOccurred"
        case WKError.javaScriptResultTypeIsUnsupported.rawValue:
            return "javaScriptResultTypeIsUnsupported"
        default:
            return nil
        }
    }

    func onWebResourceError(_ error: NSError) {
        channel.invokeMethod("onWebResourceError", arguments: [
            "errorCode": error.code,
            "domain": error.domain,
            "description": error.description,
            "errorType": WebViewController.errorCodeToString(code: error.code) as Any,
        ])
    }
}

extension NSImage {
    func tint(color: NSColor) -> NSImage {
        let image = copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()

        return image
    }
}
