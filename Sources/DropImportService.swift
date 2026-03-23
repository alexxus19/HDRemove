import Foundation
import UniformTypeIdentifiers

enum DropImportService {
    private static let preferredDataTypes: [UTType] = [
        .heic,
        .jpeg,
        .png,
        .tiff,
        .bmp,
        .gif,
        .webP,
        .image
    ]

    static func importDroppedImageURLs(from providers: [NSItemProvider]) async -> [URL] {
        await withTaskGroup(of: URL?.self) { group in
            for provider in providers {
                group.addTask {
                    if let fileURL = await loadFileURL(from: provider) {
                        return fileURL
                    }

                    return await loadImageDataAsTempFile(from: provider)
                }
            }

            var urls: [URL] = []
            for await url in group {
                if let url {
                    urls.append(url)
                }
            }

            return urls
        }
    }

    private static func loadFileURL(from provider: NSItemProvider) async -> URL? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url.standardizedFileURL)
                    return
                }

                if let nsURL = item as? NSURL, let url = nsURL as URL? {
                    continuation.resume(returning: url.standardizedFileURL)
                    return
                }

                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url.standardizedFileURL)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private static func loadImageDataAsTempFile(from provider: NSItemProvider) async -> URL? {
        guard let requestedType = preferredDataTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: requestedType.identifier) { data, _ in
                guard let data else {
                    continuation.resume(returning: nil)
                    return
                }

                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("HDRemove-Drops", isDirectory: true)
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                } catch {
                    continuation.resume(returning: nil)
                    return
                }

                let ext = requestedType.preferredFilenameExtension ?? "img"
                let fileURL = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)

                do {
                    try data.write(to: fileURL, options: .atomic)
                    continuation.resume(returning: fileURL)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
