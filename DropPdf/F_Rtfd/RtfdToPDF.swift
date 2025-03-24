import Cocoa
import PDFKit

class RtfdToPDF {
    func convertRtfdToPDF(fileURL: URL) async -> Bool {
        print(">> RtfToPDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }
        
        let saveToPdfIns = SaveToPdf()
        return await saveToPdfIns.saveContentToPdf(fileURL: fileURL, docType: .rtfd)
    }
}
