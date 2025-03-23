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

        let myText = getStr(fileURL, nil)

        if let text = myText {
            let result = await SaveToPdf().saveStringToPdf(fileURL: fileURL, text: text)
            return result
        }
        return false
    }
}
