import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let clipboardChannel = FlutterMethodChannel(name: "clipboard/image",
                                                  binaryMessenger: controller.binaryMessenger)
      clipboardChannel.setMethodCallHandler({
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                // Note: this method is invoked on the UI thread.
                  guard call.method == "getClipboardImage" else {
                    result(FlutterMethodNotImplemented)
                    return
                  }
                  self.getClipboardImage(result: result)
              })
      
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
        application.applicationIconBadgeNumber = 0 // For Clear Badge Counts
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications() // To remove all delivered notifications
        center.removeAllPendingNotificationRequests()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func getClipboardImage(result: FlutterResult) {
          
            let image = UIPasteboard.general.image;
            
            if (image == nil) {
                print("no image in clipboard")
                return
            }
            
            let data = image!.jpegData(compressionQuality: 1)
            result(data)
            
        }
}
