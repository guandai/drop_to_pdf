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
    
    func getFileTimePdfName(_ fileURL: URL) -> String {
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        return NameMod.getTimeName(originalName)  // e.g. "photo_20250311_1430.pdf"
    }

    func getBundlePathes(_ fileURL: URL) -> URL {
        let newName = getFileTimePdfName(fileURL)
        
        // Append the file name to the batchTmpFolder directory
        if !FileManager.default.fileExists(atPath: appDelegateShared.batchTmpFolder.path) {
            try? FileManager.default.createDirectory(
                at: appDelegateShared.batchTmpFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return appDelegateShared.batchTmpFolder.appendingPathComponent(newName)
    }
    
    func getSiblingPathes(_ fileURL: URL) -> URL {
        let newName = getFileTimePdfName(fileURL)
        let path = fileURL.deletingLastPathComponent()
        return path.appendingPathComponent(newName)
    }
    
    func getExportPath(_ fileURL: URL) -> URL {
        if appDelegateShared.createOneFile {
            return getBundlePathes(fileURL)
        } else {
            return getSiblingPathes(fileURL)
        }
    }
    
    func check_permission(_ finalPath: URL) async -> Bool{
        return await PermissionsManager.shared.getPermission(finalPath)
    }

    // Save Data shortcut for image / pdf / String (doc)
    func saveDataToPdf(fileURL: URL, data: Data) async -> Bool {
        let finalPath = getExportPath(fileURL)
        if !(await check_permission(finalPath)) { return false }
        return tryWriteData(url: finalPath, data: data)
    }

    // Plain shortcut
    func savePlainToPdf(fileURL: URL) async -> Bool {
        let finalPath = getExportPath(fileURL)
        if !(await check_permission(finalPath)) { return false }
        return await PrintToPDF().printContentToPDF(
            finalPath: getExportPath(finalPath), fileURL: fileURL, docType: .plain)
    }

    // RfF shortcut
    func saveRtfToPdf(fileURL: URL) async -> Bool {
        let finalPath = getExportPath(fileURL)
        if !(await check_permission(finalPath)) { return false }
        return await PrintToPDF().printContentToPDF(
            finalPath: finalPath, fileURL: fileURL, docType: .rtf)
    }

    // docx
    func savePdfDocumentToPdf(fileURL: URL, pdfDoc: PDFDocument) async -> Bool {
        let finalPath = getExportPath(fileURL)
        if !(await check_permission(finalPath)) { return false }
        guard let pdfData = pdfDoc.dataRepresentation() else {
            print("❌ Failed to convert PDFDocument to Data")
            return false
        }
        return tryWriteData(url: finalPath, data: pdfData)
    }

    // by docType for (txt plains, rtfd, html)
    func saveContentToPdf(
        fileURL: URL, docType: NSAttributedString.DocumentType
    ) async -> Bool {
        let finalPath = getExportPath(fileURL)
        if !(await check_permission(finalPath)) { return false }
        return await PrintToPDF().printContentToPDF(
            finalPath: finalPath, fileURL: fileURL, docType: docType)
    }
    
    func saveBundleToPdf(_ sourceTempFolder: URL, _ fileURL: URL) async -> Bool {
        let finalPath = getSiblingPathes(fileURL)
        if !(await check_permission(finalPath)) { return false }
        return await bundleToOneFile(sourceTempFolder, finalPath)
    }

    // Data write to file
    func tryWriteData(url: URL, data: Data) -> Bool {
        do {
            print(">>> debug url in tryWriteData: \(url.path)")
            try data.write(to: url, options: .atomic)
            print("✅ PDF saved to: \(url.path)")
//            openFolder(url.deletingLastPathComponent())
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
    
    func combineAndWritePdf(_ combinedPDF: PDFDocument, _ finalUrl: URL) async -> Bool {
        // Write the combined PDF to the final URL
        do {
            let result: Bool = try await withCheckedThrowingContinuation { continuation in
                if combinedPDF.write(to: finalUrl) {
                    print("✅ Combined PDF saved to: \(finalUrl.path)")
                    continuation.resume(returning: true)
                } else {
                    print("❌ Failed to save combined PDF to: \(finalUrl.path)")
                    continuation.resume(returning: false)
                }
            }
            return result // Use the returned result
        } catch {
            print("❌ Error saving combined PDF: \(error)")
            return false // Failure case
        }
    }
    
    func bundleToOneFile(_ sourceTempFolder: URL, _ finalUrl: URL) async -> Bool {
        // Create a PDFDocument to hold the combined PDF
        let combinedPDF = PDFDocument()

        // Get all PDF files in the folder
        let fileManager = FileManager.default
        guard let fileUrls = try? fileManager.contentsOfDirectory(
            at: sourceTempFolder,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles)
        else {
            print("❌ Failed to get contents of directory: \(sourceTempFolder.path)")
            return false
        }

        // Filter only PDF files
        let pdfUrls = fileUrls.filter { $0.pathExtension.lowercased() == "pdf" }

        // Sort PDF URLs based on the timestamp in the filename
        let sortedPdfUrls = getSortedPdf(pdfUrls)
        bundleInsertPage(sortedPdfUrls, combinedPDF)

        return await combineAndWritePdf(combinedPDF, finalUrl)
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
