import AppKit
import Cocoa
import Foundation
import SwiftUI
import UniformTypeIdentifiers  // for UTType, available in macOS 11+

class ProcessFile: ObservableObject {
    func processDroppedFiles(_ urls: [URL], _ appDelegate: AppDelegate) async
        -> [URL: Bool]
    {
        var results: [URL: Bool] = [:]
        for url in urls {
            print("📂 Dropped file: \(url.path)")
            let success = await processOneFile(
                url: url, appDelegate: appDelegate)
            await updateProcessResult(
                url: url, success: success, appDelegate: appDelegate)

            if !success {
                print(
                    "❌ ERROR: Unsupported file type or failed conversion → \(url.lastPathComponent)"
                )
            }
            results[url] = success
        }
        return results
    }

    @MainActor
    private func updateProcessResult(
        url: URL, success: Bool, appDelegate: AppDelegate
    ) {
        let newKey = (appDelegate.processResult.keys.max() ?? 0) + 1
        appDelegate.processResult[newKey] = (url, success)
    }

    /// 🔹 Process a single file and determines the correct conversion method
    func processOneFile(url: URL, appDelegate: AppDelegate) async -> Bool {
        print("📂 Processing file: \(url.path)")
        let isPDFFileIns = self.isPDFFile
        let isIllustratorFileIns = self.isIllustratorFile
        let isRTFFileIns = self.isRTFFile
        let isDocFileIns = self.isDocFile
        let isDocxFileIns = self.isDocxFile
        let isImageFileIns = self.isImageFile
        let isTextFileIns = self.isTextFile
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                Task {
                    if false {
                        print("pass")
                    } else if isPDFFileIns(url) {
                        return await PdfToPDF().convertPdfToPDF(fileURL: url)
                    } else if isIllustratorFileIns(url) {
                        return await PdfToPDF().convertPdfToPDF(fileURL: url)
                    } else if isRTFFileIns(url) {
                        return await RtfToPDF().convertRtfToPDF(fileURL: url)
                    } else if isDocFileIns(url) {
                        return await DocToPDF().convertDocToPDF(fileURL: url)
                    } else if isDocxFileIns(url) {
                        return await DocxToPDF().convertDocxToPDF(fileURL: url)
                    } else if isImageFileIns(url) {
                        return await ImageToPDF().convertImageToPDF(fileURL: url)
                    } else if isTextFileIns(url) {
                        return await TxtToPDF().convertTxtToPDF(fileURL: url)
                    } else {
                        print(
                            "⚠️ Unsupported file type → \(url.lastPathComponent)"
                        )
                        return false
                    }
                }
            }
        }
    }

    func isIllustratorFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let header = String(data: data.prefix(12), encoding: .ascii) {
                return header.hasPrefix("%PDF-")
                    || header.hasPrefix("%!PS-Adobe-")
            }
        } catch {
            print(
                "❌ Error reading file for AI check: \(fileURL.path), \(error)")
        }
        return false
    }

//    func isRTFFile(at fileURL: URL) -> Bool {
//        // Attempt to read a small chunk from the file
//        guard let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
//            let textSample = String(data: data.prefix(8), encoding: .utf8)
//        else {
//            return false
//        }
//        return textSample.hasPrefix("{\\rtf")
//    }
    
    func isRTFFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let textSample = String(data: data.prefix(16), encoding: .utf8) {
                return textSample.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()
                .hasPrefix("{\\rtf")
            }
        } catch {
            print(
                "❌ Error reading file for RTF check: \(fileURL.path), \(error)")
        }
        return false
    }

    func isPDFFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let header = String(data: data.prefix(5), encoding: .ascii) {
                return header == "%PDF-"
            }
        } catch {
            print(
                "❌ Error reading file for PDF check: \(fileURL.path), \(error)")
        }
        return false
    }

    func isTextFile(_ fileURL: URL) -> Bool {
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [
                .contentTypeKey
            ])
            // `contentType` is a UTType? in Swift 5.5+
            return resourceValues.contentType != nil
        } catch {
            print(
                "❌ Error retrieving contentType for: \(fileURL.path), \(error)")
            return false
        }
    }

    /// 🔹 Check if the file is an image
    func isImageFile(_ fileURL: URL) -> Bool {
        return NSImage(contentsOf: fileURL) != nil
    }

    /// 🔹 Check if the file is a DOCX
    func isDocxFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            // ZIP archives typically start with: 0x50 0x4B 0x03 0x04
            return data.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04])
        } catch {
            return false
        }
    }

    func isDocFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            // OLE2 magic bytes: D0 CF 11 E0
            let ole2Magic = Data([0xD0, 0xCF, 0x11, 0xE0])
            return data.prefix(4) == ole2Magic
        } catch {
            return false
        }
    }
}
