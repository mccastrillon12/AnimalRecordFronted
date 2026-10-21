import Flutter
import UIKit
import MSAL
import Photos
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  private let sharedFilesChannelName = "com.animalrecord/shared_files"
  private let fileDownloadChannelName = "com.animalrecord/file_download"
  private let sharedAppGroup = "group.com.animalRecord.animalRecord.shared"
  private let sharedQueueFile = "shared_files.json"
  private var sharedFilesChannel: FlutterMethodChannel?
  private var fileDownloadChannel: FlutterMethodChannel?
  private var flutterIsReadyForSharedFiles = false
  private var pendingDocumentFiles: [[String: String]] = []
  private var pendingDocumentExportResult: FlutterResult?
  private var pendingDocumentExportURL: URL?

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

      fileDownloadChannel = FlutterMethodChannel(
        name: fileDownloadChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      fileDownloadChannel?.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveFile" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let arguments = call.arguments as? [String: Any],
              let fileName = arguments["fileName"] as? String,
              !fileName.isEmpty,
              let mimeType = arguments["mimeType"] as? String,
              !mimeType.isEmpty,
              let typedData = arguments["bytes"] as? FlutterStandardTypedData,
              !typedData.data.isEmpty
        else {
          result(FlutterError(
            code: "INVALID_DOWNLOAD",
            message: "No hay un archivo válido para descargar.",
            details: nil
          ))
          return
        }

        if mimeType.hasPrefix("image/") {
          self?.savePhotoToLibrary(
            named: fileName,
            data: typedData.data,
            result: result
          )
          return
        }

        self?.presentDocumentExporter(
          named: fileName,
          data: typedData.data,
          result: result
        )
      }
    }

    return didFinishLaunching
  }

  private func savePhotoToLibrary(
    named fileName: String,
    data: Data,
    result: @escaping FlutterResult
  ) {
    requestPhotoLibraryAddAccess { granted in
      guard granted else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "PHOTO_LIBRARY_PERMISSION_DENIED",
            message: "Se necesita permiso para guardar la imagen en Fotos.",
            details: nil
          ))
        }
        return
      }

      var localIdentifier: String?
      PHPhotoLibrary.shared().performChanges {
        let request = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = fileName
        request.addResource(with: .photo, data: data, options: options)
        localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
      } completionHandler: { saved, error in
        DispatchQueue.main.async {
          if saved {
            result(localIdentifier ?? "photos://saved")
          } else {
            result(FlutterError(
              code: "PHOTO_SAVE_FAILED",
              message: "No fue posible guardar la imagen en Fotos.",
              details: error?.localizedDescription
            ))
          }
        }
      }
    }
  }

  private func requestPhotoLibraryAddAccess(
    completion: @escaping (Bool) -> Void
  ) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        completion(status == .authorized || status == .limited)
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        completion(status == .authorized)
      }
    }
  }

  private func presentDocumentExporter(
    named fileName: String,
    data: Data,
    result: @escaping FlutterResult
  ) {
    guard pendingDocumentExportResult == nil else {
      result(FlutterError(
        code: "DOWNLOAD_IN_PROGRESS",
        message: "Ya hay una descarga en curso.",
        details: nil
      ))
      return
    }

    do {
      let exportDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("animal_record_downloads", isDirectory: true)
      try FileManager.default.createDirectory(
        at: exportDirectory,
        withIntermediateDirectories: true
      )
      let sourceURL = uniqueDestination(
        in: exportDirectory,
        fileName: fileName
      )
      try data.write(to: sourceURL, options: .atomic)

      guard let presenter = topViewController(from: window?.rootViewController) else {
        try? FileManager.default.removeItem(at: sourceURL)
        result(FlutterError(
          code: "DOWNLOAD_UNAVAILABLE",
          message: "No fue posible abrir Guardar en Archivos.",
          details: nil
        ))
        return
      }

      pendingDocumentExportResult = result
      pendingDocumentExportURL = sourceURL
      let documentPicker = UIDocumentPickerViewController(
        forExporting: [sourceURL],
        asCopy: true
      )
      documentPicker.delegate = self
      presenter.present(documentPicker, animated: true)
    } catch {
      result(FlutterError(
        code: "DOWNLOAD_FAILED",
        message: "No fue posible preparar el archivo para descargar.",
        details: error.localizedDescription
      ))
    }
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    finishDocumentExport(result: urls.isEmpty ? nil : "files://saved")
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishDocumentExport(result: nil)
  }

  private func finishDocumentExport(result value: Any?) {
    let result = pendingDocumentExportResult
    let sourceURL = pendingDocumentExportURL
    pendingDocumentExportResult = nil
    pendingDocumentExportURL = nil
    if let sourceURL {
      try? FileManager.default.removeItem(at: sourceURL)
    }
    result?(value)
  }

  private func topViewController(from root: UIViewController?) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigationController = root as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabController = root as? UITabBarController {
      return topViewController(from: tabController.selectedViewController)
    }
    return root
  }

  private func uniqueDestination(in directory: URL, fileName: String) -> URL {
    let initial = directory.appendingPathComponent(fileName)
    guard FileManager.default.fileExists(atPath: initial.path) else {
      return initial
    }

    let fileExtension = initial.pathExtension
    let baseName = initial.deletingPathExtension().lastPathComponent
    var copyNumber = 1
    while true {
      let suffix = fileExtension.isEmpty ? "" : ".\(fileExtension)"
      let candidate = directory.appendingPathComponent(
        "\(baseName) (\(copyNumber))\(suffix)"
      )
      if !FileManager.default.fileExists(atPath: candidate.path) {
        return candidate
      }
      copyNumber += 1
    }
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
