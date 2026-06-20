import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[startup-native] app didFinishLaunching started")
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    NSLog("[startup-native] app didFinishLaunching finished")
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    NSLog("[startup-native] plugin registration started")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    NSLog("[startup-native] plugin registration finished")
  }
}
