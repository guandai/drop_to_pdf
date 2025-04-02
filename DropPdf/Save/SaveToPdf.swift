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
            return finalURL
        }
        return url
    }

    func getPathes(_ fileURL: URL) -> (URL, URL) {
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = NameMod.getTimeName(originalName)  // e.g. "photo_20250311_1430.pdf"
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
            openFolder(url.deletingLastPathComponent())
            return true
        } catch {
            print("❌ ERROR: Failed to save PDF, Error: \(error)")
            return false
        }
    }

    func bundleInsertPage(_ sortedPdfUrls: [URL], _ combinedPDF: PDFDocument) {
        // Add each PDF file to the combined PDF in sorted order
        for (index, pdfUrl) in sortedPdfUrls.enumerated() {
            guard let pdfDocument = PDFDocument(url: pdfUrl) else {
                print("❌ Failed to load PDF: \(pdfUrl.path)")
                continue
            }

            // Append each page of the current PDF to the combined PDF
            for pageIndex in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    combinedPDF.insert(page, at: combinedPDF.pageCount)
                }
            }

            print("✅ Added PDF \(index + 1): \(pdfUrl.lastPathComponent)")
        }
    }
    
    func getSortedPdf(_ pdfUrls: [URL]) -> [URL] {
        // Sort PDF URLs based on the timestamp in the filename
        return pdfUrls.sorted { url1, url2 in
            // Extract timestamp from filename
            let timestamp1 = extractTimestamp(from: url1.lastPathComponent)
            let timestamp2 = extractTimestamp(from: url2.lastPathComponent)

            // Compare timestamps
            return timestamp1 < timestamp2
        }
    }
    
    func combineAndWritePdf(_ combinedPDF: PDFDocument, _ finalUrl: URL) -> Bool {
        // Write the combined PDF to the final URL
        if combinedPDF.write(to: finalUrl) {
            print("✅ Combined PDF saved to: \(finalUrl.path)")
            return true
        }
        print("❌ Failed to save combined PDF to: \(finalUrl.path)")
        return false
    }
    
    func bundleToOneFile(_ folderUrl: URL, _ finalUrl: URL) -> Bool {
        // Create a PDFDocument to hold the combined PDF
        let combinedPDF = PDFDocument()

        // Get all PDF files in the folder
        let fileManager = FileManager.default
        guard let fileUrls = try? fileManager.contentsOfDirectory(
            at: folderUrl,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles)
        else {
            print("❌ Failed to get contents of directory: \(folderUrl.path)")
            return false
        }

        // Filter only PDF files
        let pdfUrls = fileUrls.filter { $0.pathExtension.lowercased() == "pdf" }

        // Sort PDF URLs based on the timestamp in the filename
        let sortedPdfUrls = getSortedPdf(pdfUrls)

        bundleInsertPage(sortedPdfUrls, combinedPDF)

        return combineAndWritePdf(combinedPDF, finalUrl)
    }

    // Helper function to extract timestamp from filename
    private func extractTimestamp(from filename: String) -> Date {
        // Define the date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"

        // Extract the timestamp string from the filename
        let components = filename.components(separatedBy: "_")
        if components.count > 1 {
            let timestampString = components[components.count - 2] + "_" + components[components.count - 1].replacingOccurrences(of: ".pdf", with: "")

            // Convert the timestamp string to a Date object
            if let date = dateFormatter.date(from: timestampString) {
                return date
            }
        }

        return Date.distantPast // Or Date() if you prefer current date as default
    }


    func openFolder(_ folderURL: URL) {
        NSWorkspace.shared.open(folderURL)
    }
}
