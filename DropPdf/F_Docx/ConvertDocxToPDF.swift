import Cocoa
import PDFKit
import ZIPFoundation

final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

@MainActor
class DocxToPDF {
    var pages: [NSView] = []
    var currentView: NSView!
    var yOffset: CGFloat = 0

    func unzipDocxFile(docxURL: URL, to destinationURL: URL) throws {
        try FileManager.default
            .createDirectory(
                at: destinationURL,
                withIntermediateDirectories: true
            )
        try FileManager.default.unzipItem(at: docxURL, to: destinationURL)
    }

    func convertDocxToPDF(fileURL: URL) async -> Bool {
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        let currentViewCopy = self.currentView ?? NSView()
        let yOffsetCopy = self.yOffset
        let pagesBox = Box(self.pages)
        let currentViewBox = Box(currentViewCopy)
        let yOffsetBox = Box(yOffsetCopy)
        let unzipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString
            )

        do {
            try await MainActor.run {
                try self.unzipDocxFile(docxURL: fileURL, to: unzipURL)
            }

            let docxPro = ConvertDocxProcess(
                pages: { pagesBox.value },
                setPages: { pagesBox.value = $0 },
                currentView: { currentViewBox.value },
                setCurrentView: { currentViewBox.value = $0 },
                yOffset: { yOffsetBox.value },
                setYOffset: { yOffsetBox.value = $0 }
            )

            docxPro.initPage()
            docxPro.parseData(unzipURL, docxProcess: docxPro)
            let pdfDoc = await docxPro.insertPages()
            let saveToPdfIns = SaveToPdf()
            return await saveToPdfIns.savePdfDocumentToPdf(
                fileURL: fileURL, pdfDoc: pdfDoc)
        } catch {
            print("❌ Error: \(error)")
            fileURL.stopAccessingSecurityScopedResource()
            return false
        }

    }
}
