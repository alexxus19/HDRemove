import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let dropTypes = [UTType.fileURL.identifier, UTType.image.identifier]

    @State private var droppedFiles: [DroppedImage] = []
    @State private var exportFormat: ExportFormat = .jpeg
    @State private var scalePercent: Double = 100
    @State private var jpegQuality: Double = 90
    @State private var isDropTargeted = false
    @State private var isExporting = false
    @State private var statusMessage = "Ziehe Bilder in die Fläche und exportiere sie als SDR."

    private var qualitySliderEnabled: Bool {
        if exportFormat.supportsQualityControl {
            return true
        }

        if exportFormat == .original {
            return droppedFiles.contains { ExportFormat.supportsQualityControl(sourceType: $0.description.sourceType) }
        }

        return false
    }

    var body: some View {
        VStack(spacing: 22) {
            dropZone
            controls
        }
        .padding(28)
        .background(
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.97, blue: 0.98), Color(red: 0.90, green: 0.94, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .font(.system(size: 14, weight: .regular, design: .monospaced))
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(isDropTargeted ? Color.accentColor : Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 3, dash: [12, 8]))
                )
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 14)

            VStack(spacing: 14) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text("Bilder hier ablegen")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))

                Text("Mehrere Dateien werden verarbeitet. HEIC, JPEG, PNG, TIFF, WebP und andere lesbare Bildformate sind erlaubt.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)

                if droppedFiles.isEmpty {
                    Text("Beim Export werden die Dateien als 8-Bit-sRGB neu geschrieben, damit HDR-Metadaten und Extended-Range-Darstellung entfernt werden.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 540)
                } else {
                    VStack(spacing: 10) {
                        Text("\(droppedFiles.count) Datei(en) bereit")
                            .font(.system(size: 16, weight: .semibold))

                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(droppedFiles) { file in
                                    HStack(spacing: 8) {
                                        Text(file.url.lastPathComponent)
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Button {
                                            removeFromList(file)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Color.red.opacity(0.85))
                                        }
                                        .buttonStyle(.plain)
                                        .help("Aus Liste löschen")
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                        }
                        .frame(maxWidth: 560, maxHeight: 160)
                        .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 8)

                        Text("Tippen oder klicken, um Bilder zu wählen")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            openImagePicker()
        }
        .onDrop(of: dropTypes, isTargeted: $isDropTargeted, perform: handleItemProviders)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exportformat")
                        .font(.system(size: 13, weight: .semibold))
                    Picker("", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.label).tag(format)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }

                sliderBlock(
                    title: "Skalierung",
                    valueText: "\(Int(scalePercent)) %",
                    value: $scalePercent,
                    range: 10...100,
                    accent: Color(red: 0.15, green: 0.45, blue: 0.75)
                )

                sliderBlock(
                    title: "Qualität",
                    valueText: "\(Int(jpegQuality)) %",
                    value: $jpegQuality,
                    range: 10...100,
                    accent: Color(red: 0.78, green: 0.38, blue: 0.18)
                )
                .opacity(qualitySliderEnabled ? 1 : 0.35)
                .allowsHitTesting(qualitySliderEnabled)

                Spacer(minLength: 0)

                Button(action: exportFiles) {
                    if isExporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Exportieren")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(droppedFiles.isEmpty || isExporting)
            }

            HStack {
                Text(statusMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if !droppedFiles.isEmpty {
                    Button("Liste leeren", role: .destructive) {
                        droppedFiles.removeAll()
                        statusMessage = "Liste geleert."
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func sliderBlock(title: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 8)
                Text(valueText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range, step: 1)
                .tint(accent)
        }
        .frame(width: 210)
    }

    private func mergeDroppedURLs(_ items: [URL]) -> Bool {
        let existing = Set(droppedFiles.map(\.url))
        let supported = items
            .map { $0.standardizedFileURL }
            .filter { !existing.contains($0) }
            .compactMap { url in
                ImageProcessor.inspectImage(at: url).map { DroppedImage(url: url, description: $0) }
            }

        if supported.isEmpty {
            statusMessage = "Keine lesbaren Bilddateien erkannt."
            return false
        }

        droppedFiles.append(contentsOf: supported)
        statusMessage = "\(supported.count) Bilddatei(en) hinzugefügt."
        return true
    }

    private func handleItemProviders(_ providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else {
            return false
        }

        Task {
            let urls = await DropImportService.importDroppedImageURLs(from: providers)
            await MainActor.run {
                _ = mergeDroppedURLs(urls)
            }
        }

        return true
    }

    private func openImagePicker() {
        let panel = NSOpenPanel()
        panel.title = "Bilder auswählen"
        panel.message = "Wähle ein oder mehrere Bilder zum SDR-Export."
        panel.prompt = "Hinzufügen"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]

        guard panel.runModal() == .OK else {
            return
        }

        _ = mergeDroppedURLs(panel.urls)
    }

    private func removeFromList(_ file: DroppedImage) {
        droppedFiles.removeAll { $0.id == file.id }
        statusMessage = "Datei aus der Liste entfernt."
    }

    private func exportFiles() {
        guard let destinationFolder = chooseExportFolder() else {
            statusMessage = "Export abgebrochen."
            return
        }

        let request = ExportRequest(
            format: exportFormat,
            scaleFactor: scalePercent / 100,
            jpegQuality: jpegQuality / 100,
            destinationFolder: destinationFolder
        )

        isExporting = true
        statusMessage = "Export läuft..."

        Task {
            let result = ImageProcessor.export(images: droppedFiles, using: request)
            await MainActor.run {
                isExporting = false
                switch result {
                case .success(let summary):
                    let successful = Set(summary.successURLs.map(\.standardizedFileURL))
                    droppedFiles.removeAll { successful.contains($0.url.standardizedFileURL) }

                    statusMessage = "\(summary.successCount) Datei(en) exportiert nach \(destinationFolder.path)."
                    if !summary.failures.isEmpty {
                        statusMessage += " \(summary.failures.count) Datei(en) konnten nicht verarbeitet werden."
                    }
                case .failure(let error):
                    statusMessage = error.localizedDescription
                }
            }
        }
    }

    private func chooseExportFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Exportordner wählen"
        panel.message = "Die Bilder werden als SDR-Dateien in diesen Ordner geschrieben."
        panel.prompt = "Ordner wählen"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }
}