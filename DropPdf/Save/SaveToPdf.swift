import Cocoa
import SwiftUICore
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
    
    private var appDelegateShared: AppDelegate {
        // Ensure thread-safe access to AppDelegate.shared
        if !Thread.isMainThread {
            return DispatchQueue.main.sync {
                return AppDelegate.shared
            }
        }
        return AppDelegate.shared
    }

    func checkBundle(_ url: URL) -> URL {
        if appDelegateShared.createOneFile {
            // Extract the file name from the input URL
            let fileName = url.lastPathComponent
            
            // Append the file name to the batchTmpFolder directory
            if !FileManager.default.fileExists(atPath: appDelegateShared.batchTmpFolder.path) {
                try? FileManager.default.createDirectory(
                    at: appDelegateShared.batchTmpFolder, withIntermediateDirectories: true, attributes: nil)
            }
            let finalURL = appDelegateShared.batchTmpFolder.appendingPathComponent(fileName)
            print(">>>>>>>> Bundle Final URL: \(finalURL)")
            return finalURL
        }
        return url
    }

    func getPathes(_ fileURL: URL) -> (URL, URL) {
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = NameMod.getTimeName(name: originalName)  // e.g. "photo_20250311_1430.pdf"
        let path = fileURL.deletingLastPathComponent()
        let finalPath = checkBundle(path.appendingPathComponent(newName))
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
                print(">>>  reject  permission")
                return false
            }
        }
        return true
    }

    func permissionWrapper(_ finalPath: URL) -> (@escaping () async -> Bool)
        async -> Bool
    {
        func fn(_ callback: @escaping () async -> Bool) async -> Bool {
            let granted = await self.getPermission(finalPath)
            if !granted {
                return false
            }
            return await callback()
        }
        return fn
    }

    func CallbackToPdf(_ finalPath: URL, _ callback: @escaping () -> Bool) async
        -> Bool
    {
        return await permissionWrapper(finalPath)(callback)
    }

    // Save Data shortcut for image / pdf / String (doc)
    func saveDataToPdf(fileURL: URL, data: Data) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() -> Bool {
            return tryWriteData(url: finalPath, data: data)
        }
        return await CallbackToPdf(finalPath, callback)
    }

    // Plain shortcut
    func savePlainToPdf(fileURL: URL) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() async -> Bool {
            return await PrintToPDF().printContentToPDF(
                finalPath: finalPath, fileURL: fileURL, docType: .plain)
        }
        return await permissionWrapper(finalPath)(callback)
    }

    // RfF shortcut
    func saveRtfToPdf(fileURL: URL) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() async -> Bool {
            return await PrintToPDF().printContentToPDF(
                finalPath: finalPath, fileURL: fileURL, docType: .rtf)
        }
        return await permissionWrapper(finalPath)(callback)
    }

    // docx
    func savePdfDocumentToPdf(fileURL: URL, pdfDoc: PDFDocument) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() -> Bool {
            guard let pdfData = pdfDoc.dataRepresentation() else {
                print("❌ Failed to convert PDFDocument to Data")
                return false
            }
            return tryWriteData(url: finalPath, data: pdfData)
        }
        return await permissionWrapper(finalPath)(callback)
    }

    // by docType for (txt plains, rtfd, html)
    func saveContentToPdf(
        fileURL: URL, docType: NSAttributedString.DocumentType
    ) async -> Bool {
        let (_, finalPath) = getPathes(fileURL)
        func callback() async -> Bool {
            return await PrintToPDF().printContentToPDF(
                finalPath: finalPath, fileURL: fileURL, docType: docType)
        }
        return await permissionWrapper(finalPath)(callback)
    }

    // Data write to file
    func tryWriteData(url: URL, data: Data) -> Bool {
        do {
            print(">>>>>>>> url in tryWriteData: \(url.path)")
            try data.write(to: url, options: .atomic)
            print("✅ PDF saved to: \(url.path)")
            // openFolder(url.deletingLastPathComponent())  // Open the folder
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
