import Cocoa
import PDFKit

class PdfToPDF {
    func convertPdfToPDF(fileURL: URL) async -> Bool {
        print(">> convertPdfToPDF")
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let saveToPdfIns = SaveToPdf()
                guard getDidStart(fileURL: fileURL) else {
                    print("❌ Security-scoped resource access failed: \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }

                do {
                    let pdfData = try Data(contentsOf: fileURL)
                    Task {
                        let immutablePdfData = pdfData as Data // ✅ Convert NSMutableData to immutable Data
                        let success = await saveToPdfIns.saveDataToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                        continuation.resume(returning: success)
                    }
                } catch {
                    print("❌ Error: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
