import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private static var initialLink: String?
  private var deepLinkChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let url = connectionOptions.urlContexts.first?.url {
      Self.initialLink = url.absoluteString
    } else if let url = connectionOptions.userActivities.first?.webpageURL {
      Self.initialLink = url.absoluteString
    }

    super.scene(scene, willConnectTo: session, options: connectionOptions)
    configureDeepLinkChannel()
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)

    guard let url = URLContexts.first?.url else { return }
    publishDeepLink(url)
  }

  override func scene(
    _ scene: UIScene,
    continue userActivity: NSUserActivity
  ) {
    super.scene(scene, continue: userActivity)

    guard let url = userActivity.webpageURL else { return }
    publishDeepLink(url)
  }

  private func configureDeepLinkChannel() {
    guard deepLinkChannel == nil,
          let controller = window?.rootViewController as? FlutterViewController
    else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "fr.cosmoslty.wow100/deep_links",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      if call.method == "getInitialLink" {
        result(Self.initialLink)
        return
      }

      result(FlutterMethodNotImplemented)
    }

    deepLinkChannel = channel
  }

  private func publishDeepLink(_ url: URL) {
    let link = url.absoluteString
    Self.initialLink = link
    configureDeepLinkChannel()
    deepLinkChannel?.invokeMethod("onLink", arguments: link)
  }
}
