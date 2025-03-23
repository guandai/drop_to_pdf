import Cocoa
import UniformTypeIdentifiers
import CoreText
import PDFKit

class DocToPDF {
    func extractTextFromDoc(filePath: String) -> String? {
        let url = URL(fileURLWithPath: filePath)

        // Verify if it's a supported document type
        guard let documentType = UTType(filenameExtension: url.pathExtension),
              documentType.conforms(to: .data) else {
            print("❌ Unsupported file format")
            return nil
        }

        do {
            // Try reading the file as plain text
            let textContent = try String(contentsOf: url, encoding: .isoLatin1)

            // Remove non-readable characters (if needed)
            let cleanedText = textContent.replacingOccurrences(of: "[^\\w\\s]", with: "", options: .regularExpression)

            return cleanedText
        } catch {
            print("❌ Error reading file: \(error)")
            return nil
        }
    }


    func convertDocToPDF(fileURL: URL) async -> Bool {
        print(">>convertDocToPDF")
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                Task {
                    let docData = try Data(contentsOf: URL(fileURLWithPath: fileURL.path()))
                    print(docData)
                    
                    if let docData = try? Data(contentsOf: URL(fileURLWithPath: fileURL.path())),
                       let attributedString = try? NSAttributedString(data: docData,
                           options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.docFormat],
                           documentAttributes: nil)
                    {
                        let plainText = attributedString.string
                        print(plainText)
                        
                        let result = await StringToPDF().toPdf(string: plainText, fileURL: fileURL)
                        continuation.resume(returning: result)
                        return
                    }
                    print("fail")
                    continuation.resume(returning: false)
                    
                }
            }
        }
    }

}
