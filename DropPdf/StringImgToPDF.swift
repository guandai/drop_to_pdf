import Cocoa
import PDFKit

class StringImgToPDF {
    func getDidStart(fileURL: URL) -> Bool {
        return true
    }

    func toPdf(string: String, images: [Data], fileURL: URL) async -> Bool {
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let saveToPdfIns = SaveToPdf()
                let renderContent = TxtToPDF().getContent
                let getPdfContext = saveToPdfIns.getPdfContext

                print(">>> StringImgToPDF toPdf")
                guard let (pdfData, pdfContext, mediaBox) = getPdfContext(595, 842, 10) else {
                    print("❌ ERROR: Could not load image from \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
//                let pdfData = nil
                if renderContent(pdfContext, fileURL, mediaBox) == false {
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
