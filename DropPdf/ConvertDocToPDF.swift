import Cocoa
import UniformTypeIdentifiers
import PDFKit


func convertDocToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            
            // 1) Attempt to parse .doc (or .rtf) via NSAttributedString
            guard let docString = try? NSAttributedString(
                url: fileURL,
                options: [.documentType: NSAttributedString.DocumentType.rtf],  // or .doc if you wish to attempt legacy doc parsing
                documentAttributes: nil
            ) else {
                print("ERROR: can not convert doc file")
                continuation.resume(returning: false)
                return
            }

            // 2. Create an NSTextView to hold the text for PDF rendering
            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))  // A4 size
            textView.isEditable = false
            textView.textStorage?.setAttributedString(docString)

            // 3. Convert the textView content into PDF data
            let pdfData = textView.dataWithPDF(inside: textView.bounds)
            
            let pdfConsumer = CGDataConsumer(data: pdfData as! CFMutableData)!
            var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
            let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!

            // 4) Save PDF asynchronously
            Task {
                let immutablePdfData = pdfData as Data
                let success = await saveToPdf(pdfContext: pdfContext,
                                              fileURL: fileURL,
                                              pdfData: immutablePdfData)
                continuation.resume(returning: success)
            }

            // OPTIONAL: fallback if the above Task never completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                continuation.resume(returning: false)
            }
        }
    }
}
