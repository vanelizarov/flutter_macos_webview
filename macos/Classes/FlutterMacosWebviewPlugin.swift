import Cocoa
import FlutterMacOS
import WebKit

public class FlutterMacosWebviewPlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel!
    
    lazy var parentViewController: NSViewController = {
        return NSApp.keyWindow!.contentViewController!
    }()
    var webViewController: WebViewController?

    required init(channel: FlutterMethodChannel) {
        self.channel = channel
            
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.vanelizarov.flutter_macos_webview/method",
            binaryMessenger: registrar.messenger
        )
        let instance = FlutterMacosWebviewPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "launch" {
            launch(call: call, result: result)
        } else if call.method == "close" {
            close(result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func launch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        guard let url = URL(string: args["url"] as! String) else {
            result(FlutterError(
                code: "URL_NOT_PROVIDED",
                message: "No URL to launch found in call arguments",
                details: call.arguments
            ))
            return
        }
        
        if webViewController == nil {
            webViewController = WebViewController(
                channel: channel,
                frame: parentViewController.view.frame
            )
        }
        guard let webViewCtrl = webViewController else {
            result(FlutterError(
                code: "WEB_VIEW_CONTROLLER_NOT_INITIALIZED",
                message: "WebViewController not initialized, nothing to present",
                details: nil
            ))
            return
        }
                
        webViewCtrl.loadUrl(url: url)
        
        if (!parentViewController.presentedViewControllers!.contains(webViewCtrl)) {
            parentViewController.presentAsModalWindow(webViewCtrl)
            channel.invokeMethod("onLaunch", arguments: nil)
        }
        result(nil)
    }
    
    public func close(_ result: @escaping FlutterResult) {
        guard let webViewCtrl = webViewController else {
            result(nil)
            return
        }

        if (parentViewController.presentedViewControllers!.contains(webViewCtrl)) {
            parentViewController.dismiss(webViewCtrl)
            channel.invokeMethod("onClose", arguments: nil)
        }
        webViewController = nil
        result(nil)
    }
    
}
