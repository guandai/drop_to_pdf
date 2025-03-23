import Cocoa
import PDFKit

class StringToPDF {
    func getDidStart(fileURL: URL) -> Bool {
        return true
    }

    func toPdf(string: String, fileURL: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let saveToPdfIns = SaveToPdf()

                print(">>> StringToPDF toPdf")
                guard let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(595, 842, 10) else {
                    print("❌ ERROR: Could not load image from \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                if TxtToPDF().getContent(ctx: pdfContext, url: fileURL, box: mediaBox, str: string) == false {
                    continuation.resume(returning: false)
                    return
                }

                saveToPdfIns.endContext(pdfContext)

                
                Task {
                    let immutablePdfData = pdfData as Data
                    let success = await SaveToPdf().saveToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
