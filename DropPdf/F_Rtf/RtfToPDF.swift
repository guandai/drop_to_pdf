import Cocoa
import PDFKit

class RtfToPDF {
    func convertRtfToPDF(fileURL: URL) async -> Bool {
        print(">> RtfToPDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }
        
        let result = true
        return result
    }

}
