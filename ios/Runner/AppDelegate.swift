import Flutter
import UIKit
import MSAL
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let sharedFilesChannelName = "com.animalrecord/shared_files"
  private let sharedAppGroup = "group.com.animalRecord.animalRecord.shared"
  private let sharedQueueFile = "shared_files.json"
  private var sharedFilesChannel: FlutterMethodChannel?
  private var flutterIsReadyForSharedFiles = false
  private var pendingDocumentFiles: [[String: String]] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let didFinishLaunching = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      sharedFilesChannel = FlutterMethodChannel(
        name: sharedFilesChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      sharedFilesChannel?.setMethodCallHandler { [weak self] call, result in
        guard call.method == "getInitialSharedFiles" else {
          result(FlutterMethodNotImplemented)
          return
        }
        // Dart installs its incoming-method handler before requesting the
        // initial files. From this point live deliveries are safe; before it,
        // keep files persisted so a cold launch cannot lose the intent.
        self?.flutterIsReadyForSharedFiles = true
        result(self?.consumeAllSharedFiles() ?? [])
      }
    }

    return didFinishLaunching
  }

  override func application(
      _ app: UIApplication,
      open url: URL,
      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
      if url.scheme == "animalrecord-share" {
          deliverSharedFiles()
          return true
      }
      if url.isFileURL {
          return receiveDocument(at: url)
      }
      return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String) || super.application(app, open: url, options: options)
  }

  private func deliverSharedFiles() {
      guard flutterIsReadyForSharedFiles,
            let sharedFilesChannel
      else { return }
      let files = consumeAllSharedFiles()
      guard !files.isEmpty else { return }
      sharedFilesChannel.invokeMethod("sharedFilesReceived", arguments: files)
  }

  private func consumeAllSharedFiles() -> [[String: String]] {
      let files = consumeSharedFiles() + pendingDocumentFiles
      pendingDocumentFiles.removeAll()
      return files
  }

  private func receiveDocument(at sourceURL: URL) -> Bool {
      guard let type = UTType(filenameExtension: sourceURL.pathExtension),
            type.conforms(to: .image) || type.conforms(to: .pdf)
      else { return false }

      let didAccess = sourceURL.startAccessingSecurityScopedResource()
      defer {
          if didAccess { sourceURL.stopAccessingSecurityScopedResource() }
      }

      do {
          let cacheDirectory = FileManager.default.urls(
              for: .cachesDirectory,
              in: .userDomainMask
          )[0].appendingPathComponent("shared_files", isDirectory: true)
          try FileManager.default.createDirectory(
              at: cacheDirectory,
              withIntermediateDirectories: true
          )

          let originalName = sourceURL.lastPathComponent.isEmpty
              ? (type.conforms(to: .pdf) ? "document.pdf" : "image")
              : sourceURL.lastPathComponent
          let destination = cacheDirectory.appendingPathComponent(
              "\(UUID().uuidString)-\(originalName)"
          )
          try FileManager.default.copyItem(at: sourceURL, to: destination)

          let file: [String: String] = [
              "path": destination.path,
              "name": originalName,
              "mimeType": type.preferredMIMEType ??
                  (type.conforms(to: .pdf) ? "application/pdf" : "image/jpeg"),
          ]
          if !persistSharedFiles([file]) {
              // Keep an in-memory fallback if the App Group is temporarily
              // unavailable, so an already-running Flutter engine still gets it.
              pendingDocumentFiles.append(file)
          }
          deliverSharedFiles()
          return true
      } catch {
          return false
      }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
      super.applicationDidBecomeActive(application)
      deliverSharedFiles()
  }

  private func consumeSharedFiles() -> [[String: String]] {
      guard let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: sharedAppGroup
      ) else { return [] }

      let queueURL = container.appendingPathComponent(sharedQueueFile)
      guard let data = try? Data(contentsOf: queueURL),
            let files = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
      else { return [] }

      try? FileManager.default.removeItem(at: queueURL)
      return files
  }

  @discardableResult
  private func persistSharedFiles(_ newFiles: [[String: String]]) -> Bool {
      guard !newFiles.isEmpty,
            let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: sharedAppGroup
            )
      else { return false }

      let queueURL = container.appendingPathComponent(sharedQueueFile)
      var files: [[String: String]] = []
      if let data = try? Data(contentsOf: queueURL),
         let queuedFiles = try? JSONSerialization.jsonObject(with: data)
            as? [[String: String]] {
          files = queuedFiles
      }
      files.append(contentsOf: newFiles)

      guard let data = try? JSONSerialization.data(withJSONObject: files)
      else { return false }

      do {
          try data.write(to: queueURL, options: .atomic)
          return true
      } catch {
          return false
      }
  }

  override func application(
      _ application: UIApplication,
      continue userActivity: NSUserActivity,
      restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
      // Explicitly claim Universal Links for our domain to prevent Safari fallback
      if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
         let url = userActivity.webpageURL,
         let host = url.host,
         host.contains("animalrecord.app") {
          _ = super.application(application, continue: userActivity, restorationHandler: restorationHandler)
          return true
      }
      return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
