import Cocoa
import FlutterMacOS
import WebKit

public class FlutterMacOSWebViewPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel!
    
    private lazy var parentViewController: NSViewController = {
        return NSApp.keyWindow!.contentViewController!
    }()
    private var webViewController: WebViewController?

    required init(channel: FlutterMethodChannel) {
        self.channel = channel
            
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.vanelizarov.flutter_macos_webview/method",
            binaryMessenger: registrar.messenger
        )
        let instance = FlutterMacOSWebViewPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "open" {
            open(call: call, result: result)
        } else if call.method == "close" {
            close(self, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func open(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        guard let url = URL(string: args["url"] as! String) else {
            result(FlutterError(
                code: "URL_NOT_PROVIDED",
                message: "No URL to launch found in call arguments",
                details: call.arguments
            ))
            return
        }
        
        let presentationStyle = PresentationStyle(rawValue: args["presentationStyle"] as! Int)!
                
        if webViewController == nil {
            let parentFrame = parentViewController.view.frame
            
            var width = parentFrame.size.width
            var height = parentFrame.size.height

            if args["customSize"] as! Bool {
                if let cw = args["width"] as? Double {
                    width = CGFloat(cw)
                }
                if let ch = args["height"] as? Double {
                    height = CGFloat(ch)
                }
            }
            
//            TODO
//            if args["customOrigin"] as! Bool {
//                if let cx = args["x"] as? Double {
//                    x = CGFloat(cx)
//                }
//                if let cy = args["y"] as? Double {
//                    y = CGFloat(cy)
//                }
//            }
            
            webViewController = WebViewController(
                channel: channel,
                frame: CGRect(
                    x: parentFrame.origin.x,
                    y: parentFrame.origin.y,
                    width: width,
                    height: height
                ),
                presentationStyle: presentationStyle,
                modalTitle: args["modalTitle"] as! String,
                sheetCloseButtonTitle: args["sheetCloseButtonTitle"] as! String
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
        
        webViewCtrl.javascriptEnabled = args["javascriptEnabled"] as! Bool
        webViewCtrl.userAgent = args["userAgent"] as? String
        
        webViewCtrl.loadUrl(url: url)
                
        if (!parentViewController.presentedViewControllers!.contains(webViewCtrl)) {
            if (presentationStyle == .modal) {
                parentViewController.presentAsModalWindow(webViewCtrl)
            } else {
                parentViewController.presentAsSheet(webViewCtrl)
            }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(close(_:)),
                name: kWebViewCloseNotification,
                object: nil
            )
            
            channel.invokeMethod("onOpen", arguments: nil)
            // TODO: window
        }
        result(nil)
    }
    
    @objc private func close(_ sender: Any?) {
        guard let webViewCtrl = webViewController else { return }

        if (parentViewController.presentedViewControllers!.contains(webViewCtrl)) {
            parentViewController.dismiss(webViewCtrl)
        }
        webViewController = nil
        
        NotificationCenter.default.removeObserver(
            self,
            name: kWebViewCloseNotification,
            object: nil
        )
        
        channel.invokeMethod("onClose", arguments: nil)
    }
    
    private func close(_ sender: Any?, result: @escaping FlutterResult) {
        close(sender)
        result(nil)
    }
}
