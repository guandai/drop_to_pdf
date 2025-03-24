import Cocoa
import PDFKit

class PlainToPDF {
    func convertTxtToPDF(fileURL: URL) async -> Bool {
        print("🗳️ >> convertTxtToPDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        let saveToPdfIns = SaveToPdf()
        return await saveToPdfIns.savePlainToPdf(fileURL: fileURL)
    }
}
