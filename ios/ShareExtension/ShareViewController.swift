import UIKit
import UniformTypeIdentifiers

private protocol ContainingAppOpening {
    func open(_ url: URL, from responder: UIResponder) -> Bool
}

/// Compatibility adapter for internal distributions where iOS rejects
/// `NSExtensionContext.open`. Keep this workaround isolated so it can be
/// replaced without touching the share/import workflow.
private struct ResponderChainContainingAppOpener: ContainingAppOpening {
    func open(_ url: URL, from responder: UIResponder) -> Bool {
        var currentResponder: UIResponder? = responder
        let legacyOpenSelector = NSSelectorFromString("openURL:")

        while let current = currentResponder {
            if let application = current as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return true
            }
            if current.responds(to: legacyOpenSelector) {
                current.perform(legacyOpenSelector, with: url)
                return true
            }
            currentResponder = current.next
        }

        return false
    }
}

final class ShareViewController: UIViewController {
    private let appGroup = "group.com.animalRecord.animalRecord.shared"
    private let queueFile = "shared_files.json"
    private let processingQueue = DispatchQueue(label: "com.animalrecord.share.processing")
    private var didStartProcessing = false
    private let statusLabel = UILabel()
    private let containingAppOpener: ContainingAppOpening =
        ResponderChainContainingAppOpener()

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
            finish(importSucceeded: false)
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
            DispatchQueue.main.async {
                self.finish(importSucceeded: !importedFiles.isEmpty)
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

    private func finish(importSucceeded: Bool) {
        guard importSucceeded,
              let appURL = URL(string: "animalrecord-share://shared")
        else {
            statusLabel.text = "No fue posible preparar el archivo."
            complete(after: 1.2)
            return
        }

        statusLabel.text = "Abriendo Animal Record..."
        extensionContext?.open(appURL) { [weak self] opened in
            guard let self else { return }
            DispatchQueue.main.async {
                let didOpen = opened || self.containingAppOpener.open(
                    appURL,
                    from: self
                )

                if didOpen {
                    self.complete(after: 0.25)
                } else {
                    self.statusLabel.text =
                        "Archivo preparado. Abre Animal Record para continuar."
                    self.complete(after: 1.5)
                }
            }
        }
    }

    private func complete(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
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
