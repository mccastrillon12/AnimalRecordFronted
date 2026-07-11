import UIKit
import UniformTypeIdentifiers
import UserNotifications

final class ShareViewController: UIViewController {
    private let appGroup = "group.com.animalRecord.animalRecord.shared"
    private let queueFile = "shared_files.json"
    private let processingQueue = DispatchQueue(label: "com.animalrecord.share.processing")
    private var didStartProcessing = false
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        statusLabel.text = "Preparando archivo para Animal Record..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartProcessing else { return }
        didStartProcessing = true
        importAttachments()
    }

    private func importAttachments() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem]
        else {
            finish(notificationScheduled: false)
            return
        }

        let providers = extensionItems.flatMap { $0.attachments ?? [] }
        let group = DispatchGroup()
        var importedFiles: [[String: String]] = []

        for provider in providers {
            guard let typeIdentifier = supportedTypeIdentifier(for: provider) else { continue }
            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) {
                [weak self] temporaryURL, _ in
                defer { group.leave() }
                guard let self, let temporaryURL,
                      let imported = self.copyToSharedContainer(
                          temporaryURL,
                          typeIdentifier: typeIdentifier
                      )
                else { return }

                self.processingQueue.sync {
                    importedFiles.append(imported)
                }
            }
        }

        group.notify(queue: processingQueue) { [weak self] in
            guard let self else { return }
            self.persist(importedFiles)
            guard !importedFiles.isEmpty else {
                DispatchQueue.main.async { self.finish(notificationScheduled: false) }
                return
            }
            self.scheduleContinueNotification { scheduled in
                DispatchQueue.main.async {
                    self.finish(notificationScheduled: scheduled)
                }
            }
        }
    }

    private func supportedTypeIdentifier(for provider: NSItemProvider) -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            return UTType.pdf.identifier
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return UTType.image.identifier
        }
        return nil
    }

    private func copyToSharedContainer(
        _ sourceURL: URL,
        typeIdentifier: String
    ) -> [String: String]? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        ) else { return nil }

        let directory = container.appendingPathComponent("shared_files", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let originalName = sourceURL.lastPathComponent.isEmpty
            ? defaultName(for: typeIdentifier)
            : sourceURL.lastPathComponent
        let destination = directory.appendingPathComponent(
            "\(UUID().uuidString)-\(originalName)"
        )

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return [
                "path": destination.path,
                "name": originalName,
                "mimeType": typeIdentifier == UTType.pdf.identifier
                    ? "application/pdf"
                    : mimeType(for: sourceURL),
            ]
        } catch {
            return nil
        }
    }

    private func persist(_ newFiles: [[String: String]]) {
        guard !newFiles.isEmpty,
              let container = FileManager.default.containerURL(
                  forSecurityApplicationGroupIdentifier: appGroup
              )
        else { return }

        let queueURL = container.appendingPathComponent(queueFile)
        var files: [[String: String]] = []
        if let data = try? Data(contentsOf: queueURL),
           let existingFiles = try? JSONSerialization.jsonObject(with: data)
               as? [[String: String]] {
            files = existingFiles
        }
        files.append(contentsOf: newFiles)

        if let data = try? JSONSerialization.data(withJSONObject: files) {
            try? data.write(to: queueURL, options: .atomic)
        }
    }

    private func scheduleContinueNotification(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional ||
                    settings.authorizationStatus == .ephemeral
            else {
                completion(false)
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Archivo preparado"
            content.body = "Toca para continuar en Animal Record."
            content.sound = .default
            content.userInfo = ["animalRecordAction": "sharedFiles"]

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 1,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "shared-files-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                completion(error == nil)
            }
        }
    }

    private func finish(notificationScheduled: Bool) {
        statusLabel.text = notificationScheduled
            ? "Archivo preparado. Toca la notificación para continuar en Animal Record."
            : "Archivo preparado. Abre Animal Record para continuar."

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func defaultName(for typeIdentifier: String) -> String {
        typeIdentifier == UTType.pdf.identifier ? "document.pdf" : "image"
    }

    private func mimeType(for url: URL) -> String {
        UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "image/jpeg"
    }
}
