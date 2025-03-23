import Cocoa
import PDFKit
import UniformTypeIdentifiers

class SaveToPdf {
    func getPdfContext(
        _ cgWidth: CGFloat, _ cgHeight: CGFloat, _ margin: CGFloat = 10
    ) -> (NSMutableData, CGContext, CGRect)? {
        let pdfData = NSMutableData()
        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)
        else {
            print("❌ ERROR: Could not create PDF consumer")
            return nil
        }
        var mediaBox = CGRect(
            x: margin, y: margin, width: cgWidth, height: cgHeight)
        guard
            let pdfContext = CGContext(
                consumer: pdfConsumer, mediaBox: &mediaBox, nil)
        else {
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

    
    func getPermission(_ finalPath: URL) async -> Bool {
        let permissionM = PermissionsManager.shared
        let path = finalPath.deletingLastPathComponent()
        if permissionM.isAppSandboxed() && !permissionM.isFolderGranted(path) {
            await MainActor.run {
                permissionM.requestAccess(path.path())
            }

            if !PermissionsManager().isFolderGranted(path) {
                return false
            }
        }
        return true
    }

    func permissionWrapper(_ finalPath: URL) -> (@escaping () -> Bool) async -> Bool {
        func fn(_ callback: @escaping () -> Bool) async -> Bool {
            let granted = await self.getPermission(finalPath)
            if !granted {
                return false
            }
            return callback()
        }
        return fn
    }
    
    
    func CallbackToPdf(_ finalPath: URL, _ callback: @escaping () -> Bool ) async -> Bool {
        return await permissionWrapper(finalPath)(callback)
    }
        
    func saveDataToPdf(fileURL: URL, data: Data) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() -> Bool {
            return tryWriteData(url: finalPath, data: data)
        }
        return await CallbackToPdf(finalPath, callback)
    }

    func saveStringToPdf(fileURL: URL, data: String) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() -> Bool {
            return PrintToPDF().printTextToPDF(finalPath: finalPath, text: data)
        }
        return await permissionWrapper(finalPath)(callback)
    }
    
//
//    func saveRtfToPdf(finalPath: URL, fileURL: URL) async -> Bool {
//        let (_, finalPath) = getPathes(fileURL)
//        func callback() -> Bool { return PrintToPDF().printRtfToPDF(finalPath: finalPath, fileURL: fileURL) }
//        return await permissionWrapper(finalPath)(callback)
//    }
//    
    func savePdfDocToPdf(fileURL: URL, data: PDFDocument) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() -> Bool { return data.write(to: finalPath) }
        return await permissionWrapper(finalPath)(callback)
    }
//    
//    func saveHtmlToPdf(finalPath: URL, fileURL: URL) async -> Bool {
//        let (_, finalPath) = getPathes(fileURL)
//        func callback() -> Bool { return PrintToPDF().printRtfToPDF(finalPath: finalPath, fileURL: fileURL) }
//        return await permissionWrapper(finalPath)(callback)
//    }

    func tryWriteData(url: URL, data: Data) -> Bool {
        do {
            try data.write(to: url, options: .atomic)
            print("✅ PDF saved to: \(url.path)")
            openFolder(url.deletingLastPathComponent())  // Open the folder
            return true
        } catch {
            print("❌ ERROR: Failed to save PDF, Error: \(error)")
            return false
        }
    }

    func openFolder(_ folderURL: URL) {
        NSWorkspace.shared.open(folderURL)
    }
}
