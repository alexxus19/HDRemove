import Foundation

struct DroppedImage: Identifiable {
    let id = UUID()
    let url: URL
    let description: ImageDescription
}

struct ExportRequest {
    let format: ExportFormat
    let scaleFactor: Double
    let jpegQuality: Double
    let destinationFolder: URL
}

struct ExportSummary {
    let successURLs: [URL]
    let failures: [ExportFailure]

    var successCount: Int { successURLs.count }
}

struct ExportFailure {
    let sourceURL: URL
    let message: String
}

struct ImageDescription {
    let pixelWidth: Int
    let pixelHeight: Int
    let sourceType: CFString
}