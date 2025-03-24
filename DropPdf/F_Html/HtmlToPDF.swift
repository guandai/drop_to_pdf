import Cocoa
import PDFKit

class HtmlToPDF {
    func convertHtmlToPDF(fileURL: URL) async -> Bool {
        print("🗳️ >> Using RtfToPDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }
        
        let saveToPdfIns = SaveToPdf()
        return await saveToPdfIns.saveContentToPdf(fileURL: fileURL, docType: .html)
    }
}
