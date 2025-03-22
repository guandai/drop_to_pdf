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

            let docxToPDF = DocxToPDF()
            let docxToPdfImage = DocxToPdfImage()
            let unzipPath = FileManager.default.temporaryDirectory.appendingPathComponent("ExtractedDocx")
            docxToPDF.extractDocx(docxURL: fileURL, destinationURL: unzipPath)

            Task {
                let extractedText = docxToPDF.parseDocxText(docPath: unzipPath.appendingPathComponent("word/document.xml"))
                let extractedImages = docxToPdfImage.extractImages(docxPath: unzipPath)

                print("📄 Final Extracted Text:\n\(extractedText.count)")
                print("🖼 Total Images Extracted: \(extractedImages.count)") 

                let success = await StringImgToPDF().toPdf(
                    string: extractedText,
                    images: extractedImages,
                    fileURL: fileURL
                )

                continuation.resume(returning: success)
            }
        }
    }
}
