import Foundation
import ZIPFoundation

func extractTextFromDocx(docxFileURL: URL) -> String? {
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    do {
        // ✅ Unzip the .docx file using ZIPFoundation
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: docxFileURL, to: tempDir)

        // ✅ Locate the document.xml inside the extracted contents
        let xmlFileURL = tempDir.appendingPathComponent("word/document.xml")

        if !fileManager.fileExists(atPath: xmlFileURL.path) {
            print("❌ ERROR: document.xml not found in .docx")
            return nil
        }

        // ✅ Read the document.xml content
        let xmlContent = try String(contentsOf: xmlFileURL, encoding: .utf8)

        // ✅ Extract text from XML
        return parseXMLContent(xmlContent)

    } catch {
        print("❌ ERROR: Failed to extract .docx: \(error)")
        return nil
    }
}

// ✅ Parse XML and extract text
func parseXMLContent(_ xml: String) -> String {
    let pattern = "<w:t[^>]*>(.*?)</w:t>"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let matches = regex?.matches(in: xml, options: [], range: NSRange(location: 0, length: xml.utf16.count))

    let extractedText = matches?.compactMap { match -> String? in
        if let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range])
        }
        return nil
    }.joined(separator: " ") ?? ""

    return extractedText
}
