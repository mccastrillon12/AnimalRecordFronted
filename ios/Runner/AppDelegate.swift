import Flutter
import UIKit
import MSAL

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
      _ app: UIApplication,
      open url: URL,
      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
      return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String) || super.application(app, open: url, options: options)
  }

  override func application(
      _ application: UIApplication,
      continue userActivity: NSUserActivity,
      restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
      _ = super.application(application, continue: userActivity, restorationHandler: restorationHandler)
      return true
  }
}
