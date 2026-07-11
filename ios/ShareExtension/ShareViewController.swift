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
    private let openAppButton = UIButton(type: .system)
    private let containingAppOpener: ContainingAppOpening =
        ResponderChainContainingAppOpener()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        statusLabel.text = "Preparando archivo para Animal Record..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        openAppButton.setTitle("Abrir Animal Record", for: .normal)
        openAppButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        openAppButton.isHidden = true
        openAppButton.addTarget(
            self,
            action: #selector(openContainingAppFromButton),
            for: .touchUpInside
        )

        let stack = UIStackView(arrangedSubviews: [statusLabel, openAppButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            openAppButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
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
            loadAttachment(from: provider, typeIdentifier: typeIdentifier) {
                [weak self] imported in
                defer { group.leave() }
                guard let self, let imported else { return }
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
        for identifier in provider.registeredTypeIdentifiers {
            guard let type = UTType(identifier) else { continue }
            if type.conforms(to: .pdf) {
                return identifier
            }
        }
        for identifier in provider.registeredTypeIdentifiers {
            guard let type = UTType(identifier) else { continue }
            if type.conforms(to: .image) {
                return identifier
            }
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            return UTType.pdf.identifier
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return UTType.image.identifier
        }
        return nil
    }

    /// WhatsApp may vend an attachment either as a file representation or as
    /// an in-memory item. Try both forms so the import behaves consistently
    /// with Android's content URI flow.
    private func loadAttachment(
        from provider: NSItemProvider,
        typeIdentifier: String,
        completion: @escaping ([String: String]?) -> Void
    ) {
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) {
            [weak self] temporaryURL, _ in
            guard let self else {
                completion(nil)
                return
            }

            if let temporaryURL,
               let imported = self.copyToSharedContainer(
                   temporaryURL,
                   suggestedName: provider.suggestedName,
                   typeIdentifier: typeIdentifier
               ) {
                completion(imported)
                return
            }

            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) {
                [weak self] item, _ in
                guard let self else {
                    completion(nil)
                    return
                }

                if let url = item as? URL {
                    completion(
                        self.copyToSharedContainer(
                            url,
                            suggestedName: provider.suggestedName,
                            typeIdentifier: typeIdentifier
                        )
                    )
                    return
                }
                if let data = item as? Data {
                    completion(
                        self.writeToSharedContainer(
                            data,
                            suggestedName: provider.suggestedName,
                            typeIdentifier: typeIdentifier
                        )
                    )
                    return
                }
                if let image = item as? UIImage,
                   let data = image.jpegData(compressionQuality: 1) {
                    completion(
                        self.writeToSharedContainer(
                            data,
                            suggestedName: provider.suggestedName,
                            typeIdentifier: UTType.jpeg.identifier
                        )
                    )
                    return
                }
                completion(nil)
            }
        }
    }

    private func copyToSharedContainer(
        _ sourceURL: URL,
        suggestedName: String?,
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

        let originalName = fileName(
            suggestedName: suggestedName,
            fallbackName: sourceURL.lastPathComponent,
            typeIdentifier: typeIdentifier
        )
        let destination = directory.appendingPathComponent(
            "\(UUID().uuidString)-\(originalName)"
        )

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return importedFile(
                at: destination,
                originalName: originalName,
                typeIdentifier: typeIdentifier
            )
        } catch {
            return nil
        }
    }

    private func writeToSharedContainer(
        _ data: Data,
        suggestedName: String?,
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
        let originalName = fileName(
            suggestedName: suggestedName,
            fallbackName: "",
            typeIdentifier: typeIdentifier
        )
        let destination = directory.appendingPathComponent(
            "\(UUID().uuidString)-\(originalName)"
        )

        do {
            try data.write(to: destination, options: .atomic)
            return importedFile(
                at: destination,
                originalName: originalName,
                typeIdentifier: typeIdentifier
            )
        } catch {
            return nil
        }
    }

    private func importedFile(
        at url: URL,
        originalName: String,
        typeIdentifier: String
    ) -> [String: String] {
        let type = UTType(typeIdentifier)
        return [
            "path": url.path,
            "name": originalName,
            "mimeType": type?.preferredMIMEType ??
                (type?.conforms(to: .pdf) == true ? "application/pdf" : "image/jpeg"),
        ]
    }

    private func fileName(
        suggestedName: String?,
        fallbackName: String,
        typeIdentifier: String
    ) -> String {
        let trimmedName = suggestedName?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        var resolvedName: String
        if let trimmedName, !trimmedName.isEmpty {
            resolvedName = trimmedName
        } else {
            resolvedName = fallbackName.isEmpty
                ? defaultName(for: typeIdentifier)
                : fallbackName
        }

        if URL(fileURLWithPath: resolvedName).pathExtension.isEmpty,
           let fileExtension = UTType(typeIdentifier)?.preferredFilenameExtension {
            resolvedName += ".\(fileExtension)"
        }
        return resolvedName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
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
        tryOpeningContainingApp(appURL, showFallback: true)
    }

    @objc private func openContainingAppFromButton() {
        guard let appURL = URL(string: "animalrecord-share://shared") else { return }
        openAppButton.isEnabled = false
        statusLabel.text = "Abriendo Animal Record..."
        tryOpeningContainingApp(appURL, showFallback: true)
    }

    private func tryOpeningContainingApp(_ appURL: URL, showFallback: Bool) {
        extensionContext?.open(appURL) { [weak self] opened in
            guard let self else { return }
            DispatchQueue.main.async {
                if opened {
                    self.complete(after: 0.25)
                    return
                }

                _ = self.containingAppOpener.open(appURL, from: self)
                guard showFallback else { return }

                // Do not close the extension after an unconfirmed open. If the
                // responder-chain request succeeds, iOS moves to the app. If it
                // is blocked, the user keeps a visible, retryable action.
                self.statusLabel.text = "Archivo preparado. Continúa en Animal Record."
                self.openAppButton.setTitle("Abrir Animal Record", for: .normal)
                self.openAppButton.isEnabled = true
                self.openAppButton.isHidden = false
            }
        }
    }

    private func complete(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func defaultName(for typeIdentifier: String) -> String {
        UTType(typeIdentifier)?.conforms(to: .pdf) == true ? "document.pdf" : "image"
    }
}
