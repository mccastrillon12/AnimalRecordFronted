import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroup = "group.com.animalRecord.animalRecord.shared"
    private let queueFile = "shared_files.json"
    private let processingQueue = DispatchQueue(label: "com.animalrecord.share.processing")
    private var didStartProcessing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Importando en Animal Record…"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
            finish()
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
            DispatchQueue.main.async { self.finish() }
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

    private func finish() {
        let appURL = URL(string: "animalrecord-share://shared")!
        extensionContext?.open(appURL) { [weak self] _ in
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
