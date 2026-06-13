import AuthenticationServices
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate, ASWebAuthenticationPresentationContextProviding {
  private static var initialLink: String?
  private var deepLinkChannel: FlutterMethodChannel?
  private var oauthChannel: FlutterMethodChannel?
  private var authSession: ASWebAuthenticationSession?

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
    configureOAuthChannel()
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

  private func configureOAuthChannel() {
    guard oauthChannel == nil,
          let controller = window?.rootViewController as? FlutterViewController
    else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "fr.cosmoslty.wow100/oauth",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "authenticate" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let self,
            let arguments = call.arguments as? [String: Any],
            let urlString = arguments["url"] as? String,
            let url = URL(string: urlString),
            let callbackScheme = arguments["callbackScheme"] as? String
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "OAuth URL ou callbackScheme manquant.",
          details: nil
        ))
        return
      }

      self.startAuthenticationSession(
        url: url,
        callbackScheme: callbackScheme,
        result: result
      )
    }

    oauthChannel = channel
  }

  private func startAuthenticationSession(
    url: URL,
    callbackScheme: String,
    result: @escaping FlutterResult
  ) {
    authSession?.cancel()

    let session = ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackScheme
    ) { callbackURL, error in
      if let callbackURL {
        result(callbackURL.absoluteString)
        return
      }

      if let error {
        result(FlutterError(
          code: "authentication_failed",
          message: error.localizedDescription,
          details: nil
        ))
        return
      }

      result(FlutterError(
        code: "authentication_failed",
        message: "Aucun callback OAuth reçu.",
        details: nil
      ))
    }

    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true
    authSession = session

    if !session.start() {
      result(FlutterError(
        code: "authentication_failed",
        message: "Impossible de lancer la session OAuth.",
        details: nil
      ))
    }
  }

  private func publishDeepLink(_ url: URL) {
    let link = url.absoluteString
    Self.initialLink = link
    configureDeepLinkChannel()
    deepLinkChannel?.invokeMethod("onLink", arguments: link)
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return window ?? ASPresentationAnchor()
  }
}
