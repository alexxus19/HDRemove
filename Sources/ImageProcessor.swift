import AppKit
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case original
    case png
    case jpeg
    case heic
    case webp
    case tiff
    case bmp
    case gif

    var id: String { rawValue }

    var label: String {
        switch self {
        case .original:
            return "Original"
        case .png:
            return "PNG"
        case .jpeg:
            return "JPEG"
        case .heic:
            return "HEIC"
        case .webp:
            return "WebP"
        case .tiff:
            return "TIFF"
        case .bmp:
            return "BMP"
        case .gif:
            return "GIF"
        }
    }

    var utType: UTType? {
        switch self {
        case .original:
            return nil
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .heic:
            return .heic
        case .webp:
            return .webP
        case .tiff:
            return .tiff
        case .bmp:
            return .bmp
        case .gif:
            return .gif
        }
    }

    var supportsQualityControl: Bool {
        switch self {
        case .jpeg, .heic, .webp:
            return true
        case .original, .png, .tiff, .bmp, .gif:
            return false
        }
    }

    static func supportsQualityControl(sourceType: CFString) -> Bool {
        guard let sourceType = UTType(sourceType as String) else {
            return false
        }

        return sourceType == .jpeg || sourceType == .heic || sourceType == .webP
    }

    func resolvedType(for sourceType: CFString) -> UTType {
        if let utType {
            return utType
        }

        let destinationTypes = (CGImageDestinationCopyTypeIdentifiers() as NSArray) as? [String] ?? []
        if let source = UTType(sourceType as String), destinationTypes.contains(source.identifier) {
            return source
        }

        return .png
    }
}

enum ImageProcessor {
    static func inspectImage(at url: URL) -> ImageDescription? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let type = CGImageSourceGetType(source),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        return ImageDescription(pixelWidth: width, pixelHeight: height, sourceType: type)
    }

    static func export(images: [DroppedImage], using request: ExportRequest) -> Result<ExportSummary, Error> {
        var successes: [URL] = []
        var failures: [ExportFailure] = []

        for image in images {
            do {
                try exportOne(image, using: request)
                successes.append(image.url)
            } catch {
                failures.append(ExportFailure(sourceURL: image.url, message: error.localizedDescription))
            }
        }

        return .success(ExportSummary(successURLs: successes, failures: failures))
    }

    private static func exportOne(_ droppedImage: DroppedImage, using request: ExportRequest) throws {
        guard let source = CGImageSourceCreateWithURL(droppedImage.url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            throw ProcessorError.unreadableImage
        }

        let sourceType = CGImageSourceGetType(source) ?? UTType.png.identifier as CFString
        let resolvedType = request.format.resolvedType(for: sourceType)
        let destinationURL = outputURL(for: droppedImage.url, type: resolvedType, folder: request.destinationFolder)

        let targetSize = scaledSize(for: cgImage, scaleFactor: request.scaleFactor)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let bitmap = CGContext(
                data: nil,
                width: targetSize.width,
                height: targetSize.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw ProcessorError.renderFailed
        }

        bitmap.interpolationQuality = .high
        bitmap.setFillColor(NSColor.white.cgColor)
        bitmap.fill(CGRect(origin: .zero, size: CGSize(width: targetSize.width, height: targetSize.height)))
        bitmap.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: targetSize.width, height: targetSize.height)))

        guard let rendered = bitmap.makeImage() else {
            throw ProcessorError.renderFailed
        }

        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, resolvedType.identifier as CFString, 1, nil) else {
            throw ProcessorError.destinationCreateFailed
        }

        let destinationProperties = makeDestinationProperties(for: resolvedType, quality: request.jpegQuality)
        CGImageDestinationAddImage(destination, rendered, destinationProperties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ProcessorError.writeFailed
        }
    }

    private static func scaledSize(for image: CGImage, scaleFactor: Double) -> CGSizeInt {
        let width = Double(image.width)
        let height = Double(image.height)
        let longestEdge = max(width, height)
        let clampedFactor = max(0.1, min(1.0, scaleFactor))
        let targetLongestEdge = max(1, longestEdge * clampedFactor)
        let ratio = targetLongestEdge / longestEdge

        return CGSizeInt(
            width: max(1, Int((width * ratio).rounded())),
            height: max(1, Int((height * ratio).rounded()))
        )
    }

    private static func outputURL(for sourceURL: URL, type: UTType, folder: URL) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let fileExtension = type.preferredFilenameExtension ?? sourceURL.pathExtension
        return folder.appendingPathComponent("\(baseName)_sdr.\(fileExtension)")
    }

    private static func makeDestinationProperties(for type: UTType, quality: Double) -> [CFString: Any] {
        var properties: [CFString: Any] = [
            kCGImageDestinationEmbedThumbnail: false,
            kCGImagePropertyProfileName: CGColorSpace.sRGB,
            kCGImagePropertyDepth: 8,
            kCGImagePropertyHasAlpha: type != .jpeg && type != .bmp
        ]

        if type == .jpeg || type == .heic || type == .webP {
            properties[kCGImageDestinationLossyCompressionQuality] = max(0.1, min(1.0, quality))
        }

        return properties
    }
}

private struct CGSizeInt {
    let width: Int
    let height: Int
}

private enum ProcessorError: LocalizedError {
    case unreadableImage
    case renderFailed
    case destinationCreateFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "Eine Bilddatei konnte nicht gelesen werden."
        case .renderFailed:
            return "Die SDR-Neuberechnung ist fehlgeschlagen."
        case .destinationCreateFailed:
            return "Die Zieldatei konnte nicht vorbereitet werden."
        case .writeFailed:
            return "Die Zieldatei konnte nicht geschrieben werden."
        }
    }
}