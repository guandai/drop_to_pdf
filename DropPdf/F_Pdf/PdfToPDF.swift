import Cocoa
import PDFKit

class PdfToPDF {
    func convertPdfToPDF(fileURL: URL) async -> Bool {
        print(">> convertPdfToPDF")

        let saveToPdfIns = SaveToPdf()
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        do {
            let pdfData = try Data(contentsOf: fileURL)
            return await saveToPdfIns.saveDataToPdf(fileURL: fileURL, data: pdfData as Data)
        } catch {
            print("❌ Error: \(error)")
            return false
        }
    }
}
