import Foundation
import AppKit
import ZIPFoundation
import XMLCoder



class DocxToPDF {
    // deprecated
    func extractTextFromDocx(docxFileURL: URL) -> String? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            // ✅ Unzip the .docx file using ZIPFoundation
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: docxFileURL, to: tempDir)
            print("DOCX extracted to: \(tempDir.path)")
            
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



    struct Document: Codable {
        let body: Body
    }

    struct Body: Codable {
        let paragraphs: [Paragraph]
        
        enum CodingKeys: String, CodingKey {
            case paragraphs = "w:p"
        }
    }

    struct Paragraph: Codable {
        let runs: [Run]?
        
        enum CodingKeys: String, CodingKey {
            case runs = "w:r"
        }
    }

    struct Run: Codable {
        let text: Text?
        
        enum CodingKeys: String, CodingKey {
            case text = "w:t"
        }
    }

    struct Text: Codable {
        let content: String
        
        enum CodingKeys: String, CodingKey {
            case content = ""
        }
    }

    func parseDocxText(docPath: URL) -> String {
        guard let data = try? Data(contentsOf: docPath) else { return "" }
        let decoder = XMLDecoder()
        
        do {
            let document = try decoder.decode(Document.self, from: data)
            let text = document.body.paragraphs.compactMap { $0.runs?.compactMap { $0.text?.content }.joined(separator: " ") }.joined(separator: "\n")
            return text
        } catch {
            print("Failed to parse DOCX: \(error)")
            return ""
        }
    }

    
    @Sendable func extractImages(docxPath: URL) -> [Data] {
        let mediaURL = docxPath.appendingPathComponent("word/media/")
        guard let mediaFiles = try? FileManager.default.contentsOfDirectory(at: mediaURL, includingPropertiesForKeys: nil) else { return [] }

        return mediaFiles.compactMap { file in
            guard let data = try? Data(contentsOf: file) else { return nil }
            return data  // ✅ Return Data instead of NSImage
        }
    }


    func extractDocx(docxURL: URL, destinationURL: URL) {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL) // Clean up previous extractions
            }
            
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: docxURL, to: destinationURL)
            
            print("📂 DOCX extracted to: \(destinationURL.path)")
        } catch {
            print("❌ ERROR: Failed to extract DOCX: \(error)")
        }
    }

}
