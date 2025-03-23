import Cocoa
import PDFKit
import UniformTypeIdentifiers


class SaveToPdf {
    func getPdfContext(_ cgWidth: CGFloat, _ cgHeight: CGFloat, _ margin: CGFloat = 10) -> (NSMutableData, CGContext, CGRect)? {
        let pdfData = NSMutableData()
        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            print("❌ ERROR: Could not create PDF consumer")
            return nil
        }

        var mediaBox = CGRect(x: margin, y: margin, width: cgWidth, height: cgHeight)
        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            print("❌ Failed to create PDF pdfContext")
            return nil
        }

        return (pdfData, pdfContext, mediaBox)
    }
    
    func endContext(_ pdfContext: CGContext) {
        pdfContext.endPage()
        pdfContext.closePDF()
    }
    
    func getPathes(_ fileURL: URL) -> (URL, URL) {
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = NameMod.getTimeName(name: originalName)  // e.g. "photo_20250311_1430.pdf"
        let path = fileURL.deletingLastPathComponent()
        let finalPath = path.appendingPathComponent(newName)
        return (path, finalPath)
    }

    func saveToPdf(fileURL: URL, pdfData: Data) async -> Bool {
        return await withCheckedContinuation { continuation in
            let (path, finalPath) = getPathes(fileURL)
            do {
                

                if PermissionsManager().isAppSandboxed() && !PermissionsManager.shared.isFolderGranted(path) {
                    Task { @MainActor in
                        PermissionsManager.shared.requestAccess(path.path())
                        do {
                            try pdfData.write(to: finalPath, options: .atomic)
                            print("✅ PDF saved to: \(finalPath.path)")
                            openFolder(finalPath.deletingLastPathComponent()) // Open the folder
                            return
                        } catch {
                            print("❌ ERROR: Failed to save PDF, Error: \(error)")
                        }
                    }
                    return
                }

                // 🚀 Save normally if not sandboxed
                try pdfData.write(to: finalPath, options: .atomic)
                print("✅ Successfully saved PDF to: \(finalPath.path)")
                openFolder(finalPath.deletingLastPathComponent()) // Open the folder
                continuation.resume(returning: true)
                return

            } catch {
                print("❌ ERROR: Failed to save PDF, Error: \(error)")
                continuation.resume(returning: false)
                return
            }
        }
    }

    func openFolder(_ folderURL: URL) {
        NSWorkspace.shared.open(folderURL)
    }
}


