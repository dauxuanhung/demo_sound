import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.sound.channel", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, result in
      if call.method == "getBmpOfFile",
         let args = call.arguments as? [String: Any],
         let filePath = args["filePath"] as? String {
          let bpm = SuperpoweredBridge.detectBpm(from: filePath)
          result(bpm)
      } else {
          result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
