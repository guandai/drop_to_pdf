import Cocoa
import PDFKit

class RtfdToPDF {
    func convertRtfdToPDF(fileURL: URL) async -> Bool {
        print(">> Rtfd To PDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }
        
        let saveToPdfIns = SaveToPdf()
        return await saveToPdfIns.saveContentToPdf(fileURL: fileURL, docType: .rtfd)
    }
}
