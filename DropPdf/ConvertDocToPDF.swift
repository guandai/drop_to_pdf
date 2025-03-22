import Cocoa
import UniformTypeIdentifiers
import CoreText
import PDFKit

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
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            Task {
                // let (success, string) = await RunTask().binTask(
                //     fileURL: fileURL, docBin: docBin)

                let string = extractTextFromDoc(filePath: fileURL.path())
                guard string == nil else {
                    print("❌ Could not extract text from .doc")
                    continuation.resume(returning: false)
                    return
                }

                let result = await StringImgToPDF().toPdf(string: string!, images:[], fileURL: fileURL)
                continuation.resume(returning: result)
                return
            }
        }
    }
}
