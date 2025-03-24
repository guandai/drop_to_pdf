import AppKit
import Cocoa
import Foundation
import SwiftUI
import UniformTypeIdentifiers  // for UTType, available in macOS 11+
extension AppDelegate: @unchecked Sendable {}
class ProcessFile: ObservableObject {
    func getSuccess(url: URL, appDelegate: AppDelegate) async -> Bool {
        let process = self.processOneFile
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let capturedAppDelegate = appDelegate
                Task {
                    if await process(url, capturedAppDelegate) {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    func processDroppedFiles(_ urls: [URL], _ appDelegate: AppDelegate) async -> [URL: Bool] {
        var results: [URL: Bool] = [:]
        for url in urls {
            print("📂 Dropped file: \(url.path)")
            let success = await getSuccess(url: url, appDelegate: appDelegate)
            await updateProcessResult( url: url, success: success, appDelegate: appDelegate)
            if !success {
                print( "❌ ERROR: Unsupported file type or failed conversion → \(url.lastPathComponent)")
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
        if false {
            print("⬇️ pass")
        } else if isPdfFile(url) {
            return await PdfToPDF().convertPdfToPDF(fileURL: url)
        } else if isIllustratorFile(url) {
            return await PdfToPDF().convertPdfToPDF(fileURL: url)
        } else if isRtfdFile(url) {
            return await RtfdToPDF().convertRtfdToPDF(fileURL: url)
        } else if isRtfFile(url) {
            return await RtfToPDF().convertRtfToPDF(fileURL: url)
        } else if isHtmlFile(url) {
            return await HtmlToPDF().convertHtmlToPDF(fileURL: url)
        } else if isDocFile(url) {
            return await DocToPDF().convertDocToPDF(fileURL: url)
        } else if isDocxFile(url) {
            return await DocxToPDF().convertDocxToPDF(fileURL: url)
        } else if isImageFile(url) {
            return await ImageToPDF().convertImageToPDF(fileURL: url)
        } else if isTextFile(url) {
            return await PlainToPDF().convertTxtToPDF(fileURL: url)
        } else {
            print(
                "⚠️ Unsupported file type → \(url.lastPathComponent)"
            )
            return false
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

    func isHtmlFile(_ fileURL: URL) -> Bool {
        // First, check the file extension
        let htmlExtensions = ["html", "htm"]
        if htmlExtensions.contains(fileURL.pathExtension.lowercased()) {
            return true
        }

        // Then, check the content for typical HTML markers
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let textSample = String(data: data.prefix(256), encoding: .utf8)?
                .lowercased()
            {
                return textSample.contains("<!doctype html")
                    || textSample.contains("<html")
                    || textSample.contains("<head")
                    || textSample.contains("<body")
            }
        } catch {
            print(
                "❌ Error checking file for HTML: \(fileURL.path), \(error)"
            )
        }

        return false
    }

    func isRtfdFile(_ fileURL: URL) -> Bool {
        // RTFD is a directory with .rtfd extension
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir),
              isDir.boolValue,
              fileURL.pathExtension.lowercased() == "rtfd"
        else {
            return false
        }

        // Check if it contains at least one .rtf file inside
        if let contents = try? FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil) {
            for itemURL in contents {
                if itemURL.pathExtension.lowercased() == "rtf" {
                    print("✅ Confirmed .rtfd content inside: \(itemURL.lastPathComponent)")
                    return true
                }
            }
        }

        return false
    }

    func isRtfFile(_ fileURL: URL) -> Bool {
        // Skip directories like .rtfd bundles
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), isDir.boolValue {
            print("⛔ Skipping directory in isRtfFile: \(fileURL.lastPathComponent)")
            return false
        }

        // Check for RTF signature
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let textSample = String(data: data.prefix(64), encoding: .utf8) {
                let trimmed = textSample.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let isMatch = trimmed.hasPrefix("{\\rtf")

                return isMatch
            }
        } catch {
            print("❌ Error checking file for RTF check: \(fileURL.path), \(error)")
        }

        return false
    }

    func isPdfFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let header = String(data: data.prefix(5), encoding: .ascii) {
                return header == "%PDF-"
            }
        } catch {
            print("❌ Error reading file for PDF: \(fileURL.path), \(error)")
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
            print("❌ Error retrieving contentType: \(fileURL.path), \(error)")
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
 
