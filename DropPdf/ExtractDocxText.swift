import Foundation
import AppKit
import CoreGraphics
import ImageIO
import ZIPFoundation
import XMLCoder
import UniformTypeIdentifiers


class ExtractDocxText {
    func extractDocx(docxURL: URL, destinationURL: URL) {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: docxURL, to: destinationURL)

            print("📂 DOCX extracted to: \(destinationURL.path)")
        } catch {
            print("❌ ERROR: Failed to extract DOCX: \(error)")
        }
    }

    func parseDocxText(docPath: URL) -> String {
        guard let data = try? Data(contentsOf: docPath) else {
            print("❌ ERROR: document.xml not found")
            return ""
        }

        let xmlContent = String(data: data, encoding: .utf8) ?? ""
        print("📄 RAW XML CONTENT:\n\(xmlContent.count)") // ✅ Debugging print

        let pattern = "<w:t(?: [^>]*)?>(.*?)</w:t>" // ✅ Capture all <w:t> content
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.utf16.count))

        let extractedText = matches?.compactMap { match -> String? in
            if let range = Range(match.range(at: 1), in: xmlContent) {
                return String(xmlContent[range])
            }
            return nil
        }.joined(separator: " ") ?? ""

        print("✅ Extracted Text:\n\(extractedText.count)") 
        return extractedText
    }

}
