import Cocoa
import PDFKit

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
    
    func parseData(_ unzipURL: URL, docxProcess: ConvertDocxProcess) {
        let docParser = DocxParser()
        docParser
            .parseDocument(
                at: unzipURL.appendingPathComponent("word/document.xml")
            )
        for block in docParser.contentBlocks {
            switch block {
            case .paragraph(let runs):
                docxProcess.processText(runs)
            case .image(let rId, let w, let h):
                docxProcess
                    .processImage(unzipURL: unzipURL, rId: rId, w: w , h: h)
            }
        }
    }
    
    
    func convertDocxToPDF(fileURL: URL) async -> Bool {
        print(">> convertDocxToPDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        let currentViewCopy = self.currentView ?? NSView()
        let yOffsetCopy = self.yOffset
        
        
        let pagesBox = Box(self.pages)
        let currentViewBox = Box(currentViewCopy)
        let yOffsetBox = Box(yOffsetCopy)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    let unzipURL = FileManager.default.temporaryDirectory.appendingPathComponent(
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
                        await self.parseData(unzipURL, docxProcess: docxPro)
                        // insert pages
                        let doc = await docxPro.insertPages()
                        
                        // Generate PDF
                        let (_, outputPath) = SaveToPdf().getPathes(fileURL)
                        if doc.write(to: outputPath) {
                            //  fileURL.stopAccessingSecurityScopedResource()
                            continuation.resume(returning:  true)
                            return
                        }
                        
                        // close folder
                        fileURL.stopAccessingSecurityScopedResource()
                        continuation.resume(returning: false)
                    

                    } catch {
                        DispatchQueue.main.async {
                            print("❌ Error: \(error)")
                            continuation.resume(returning: false)
                            fileURL.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            }
        }
    }
}
