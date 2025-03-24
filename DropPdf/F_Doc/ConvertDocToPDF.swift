import Cocoa
import CoreText
import PDFKit
import UniformTypeIdentifiers

class DocToPDF {
    func extractTextFromDoc(filePath: String) -> String? {
        let url = URL(fileURLWithPath: filePath)

        // Verify if it's a supported document type
        guard let documentType = UTType(filenameExtension: url.pathExtension),
            documentType.conforms(to: .data)
        else {
            print("❌ Unsupported file format")
            return nil
        }

        do {
            // Try reading the file as plain text
            let textContent = try String(contentsOf: url, encoding: .isoLatin1)

            // Remove non-readable characters (if needed)
            let cleanedText = textContent.replacingOccurrences(
                of: "[^\\w\\s]", with: "", options: .regularExpression)

            return cleanedText
        } catch {
            print("❌ Error reading file: \(error)")
            return nil
        }
    }

    func convertDocToPDF(fileURL: URL) async -> Bool {
        print(">>convertDocToPDF")
        
        let nsOption = [ NSAttributedString.DocumentReadingOptionKey
                .documentType: NSAttributedString.DocumentType
                .docFormat
        ]
        
        guard let docData = try? Data( contentsOf: URL(fileURLWithPath: fileURL.path())) else {
            print("❌ fail to get docData : \(fileURL.path)")
            return false
        }
        
        guard let attributed = try? NSAttributedString( data: docData, options: nsOption, documentAttributes: nil) else {
            print("❌ create NSAttributedString failed: \(fileURL.path)")
            return false
        }
        
        let string = attributed.string
        return await StringToPDF().stringToPdf(fileURL: fileURL, string: string)
        
//        let saveToPdfIns = SaveToPdf()
//        return await saveToPdfIns.saveContentToPdf(fileURL: fileURL, docType: .docFormat)
    }
}
