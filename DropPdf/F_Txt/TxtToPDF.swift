import Cocoa
import PDFKit

class TxtToPDF {
    func convertTxtToPDF(fileURL: URL) async -> Bool {
        print(">> convertTxtToPDF")
        let getStr = StringToPDF().getString

        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        guard let text = getStr(fileURL, nil) else {
            print( "❌ getString can not get text in TxtToPDF \(fileURL.path)")
            return false
        }
        let saveToPdfIns = SaveToPdf()
        return await saveToPdfIns.saveStringToPdf(fileURL: fileURL, data: text)
    }
}
