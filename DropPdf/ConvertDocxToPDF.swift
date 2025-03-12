import Cocoa
import PDFKit

func convertDocxToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            guard StringToPdf().getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                return continuation.resume(returning: false)
            }
            
            guard let string = extractTextFromDocx(docxFileURL: fileURL) else {
                print("❌ ERROR: No text found in .docx")
                return continuation.resume(returning: false)
            }
            
            Task {
                let result = await StringToPdf().toPdf(string: string, fileURL: fileURL);
                return continuation.resume(returning: result)
            }
        }
    }
}


