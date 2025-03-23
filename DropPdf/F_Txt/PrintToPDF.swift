import Cocoa

class PrintToPDF {
    func exportTextToPDF(text: String, to fileURL: URL) -> Bool {
        UserDefaults.standard.set(true, forKey: "NSPrintSpoolerLogToConsole")
        let printView = TextPrintView(frame: NSRect(x: 0, y: 0, width: 595, height: 842), text: text)
        let printInfo = NSPrintInfo()
        
        
        printInfo.horizontalPagination = .automatic
        printInfo.verticalPagination = .automatic
        printInfo.paperSize = NSSize(width: 595, height: 842)
        printInfo.topMargin = 20
        printInfo.bottomMargin = 20
        printInfo.leftMargin = 20
        printInfo.rightMargin = 20
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey(rawValue: NSPrintInfo.AttributeKey.jobSavingURL.rawValue)] = fileURL

        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false

        let result = operation.run()
        print(result ? "✅ PDF saved" : "❌ PDF generation failed")
        return result
    }
    
    func exportRTFToPDF(url: URL, to fileURL: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let attributedText = try? NSAttributedString(data: data, options: [
                .documentType: NSAttributedString.DocumentType.rtf
              ], documentAttributes: nil)
        else {
            print("❌ Failed to load RTF content")
            return false
        }

        let printView = RtfPrintView(frame: NSRect(x: 0, y: 0, width: 595, height: 842), attributedText: attributedText)
        let printInfo = NSPrintInfo()

        printInfo.horizontalPagination = .automatic
        printInfo.verticalPagination = .automatic
        printInfo.paperSize = NSSize(width: 595, height: 842)
        printInfo.topMargin = 20
        printInfo.bottomMargin = 20
        printInfo.leftMargin = 20
        printInfo.rightMargin = 20
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey(rawValue: NSPrintInfo.AttributeKey.jobSavingURL.rawValue)] = fileURL

        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false

        let result = operation.run()
        print(result ? "✅ PDF saved" : "❌ PDF generation failed")
        return result
    }
}
