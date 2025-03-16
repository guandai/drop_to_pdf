import Cocoa
import PDFKit

func convertDocxToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            guard getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                continuation.resume(returning: false)
                return
            }
            
//            Task {
//                let result = await StringImgToPDF().toPdf(
//                    string: extractTextFromDocx(docxFileURL: fileURL),
//                    fileURL: fileURL
//                );
//                continuation.resume(returning: result)
//                return
//            }
            
            let docxTo = DocxToPDF()
            let unzipPath = FileManager.default.temporaryDirectory.appendingPathComponent("ExtractedDocx")
            docxTo.extractDocx(docxURL: fileURL, destinationURL: unzipPath)
            
            Task {
                let success  = await StringImgToPDF().toPdf(
                    string: docxTo.parseDocxText(docPath: unzipPath.appendingPathComponent("word/document.xml")),
                    images: docxTo.extractImages(docxPath: unzipPath),
                    fileURL: fileURL)
                continuation.resume(returning: success)
                return

            }
                
        }
    }
    
}
