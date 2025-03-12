import Cocoa
import SwiftUI

class ProcessFile: ObservableObject {
    func processDroppedFiles(_ urls: [URL], _ appDelegate: AppDelegate) async -> [URL: Bool] {
        var results: [URL: Bool] = [:]
        for url in urls {
            print("📂 Dropped file: \(url.path)")
            let success = await processOneFile(url: url, appDelegate: appDelegate)
            await updateProcessResult(url: url, success: success, appDelegate: appDelegate)

            if !success {
                print("❌ ERROR: Unsupported file type or failed conversion → \(url.lastPathComponent)")
            }
            results[url] = success;
        }
        return results
    }

    @MainActor
    private func updateProcessResult(url: URL, success: Bool, appDelegate: AppDelegate) {
        appDelegate.processResult.append((url, success)) // ✅ Store result safely on main thread
    }

    /// 🔹 Process a single file and determines the correct conversion method
    func processOneFile(url: URL, appDelegate: AppDelegate) async -> Bool {
        print("📂 Processing file: \(url.path)")
        
        if isImageFile(url: url) {
            return await convertImageToPDF(fileURL: url)
        } else if isTextFile(url: url) {
            return await convertTxtToPDF(fileURL: url, appDelegate: appDelegate)
        } else if isDocx(url: url) {
            return await convertDocxToPDF(fileURL: url)
        } else if url.pathExtension.lowercased() == "doc" {
            return await convertDocToPDF(fileURL: url)
        } else if url.pathExtension.lowercased() == "rtf" {
            return await convertDocToPDF(fileURL: url)
        } else {
            print("⚠️ Unsupported file type → \(url.lastPathComponent)")
            return false
        }
    }

    /// 🔹 Check if the file is a valid text file
    func isTextFile(url: URL) -> Bool {
        return (try? String(contentsOf: url, encoding: .utf8)) != nil
    }

    /// 🔹 Check if the file is an image
    func isImageFile(url: URL) -> Bool {
        return NSImage(contentsOf: url) != nil
    }

    /// 🔹 Check if the file is a DOCX
    func isDocx(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "docx"
    }
}
