import Cocoa
import PDFKit

func convertDocToPDF(docFileURL: URL) -> Bool {
    print(">>>convertDocToPDF")
    
    // 1) catdoc in your bundle
    guard let catdocBin = Bundle.main.path(forResource: "catdoc", ofType: "") else {
        print("❌ catdoc not found in Resources")
        return false
    }
    // 2) codepage path in your bundle
    let codepagePath = (Bundle.main.resourcePath! as NSString)
        .appendingPathComponent("catdoc_data/mac-roman.txt")

    let task = Process()
    task.launchPath = catdocBin
    // 3) Pass `-m codepagePath` so it never touches /usr/local/share
    task.arguments = ["-m", codepagePath, docFileURL.path]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    do {
        // 4) Access the security-scoped resource if sandboxed
        let didStart = docFileURL.startAccessingSecurityScopedResource()
        defer { if didStart { docFileURL.stopAccessingSecurityScopedResource() } }

        try task.run()
        task.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let extractedText = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        

        guard let text = extractedText, !text.isEmpty else {
            print("❌ Could not extract text from .doc")
            return false
        }

        // Build PDF
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!

        pdfContext.beginPage(mediaBox: &mediaBox)
        NSGraphicsContext.saveGraphicsState()
        let nsCtx = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        NSGraphicsContext.current = nsCtx

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.alignment = .left
                return p
            }()
        ]
        let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
        NSString(string: text).draw(in: textRect, withAttributes: attributes)

        NSGraphicsContext.restoreGraphicsState()
        pdfContext.endPage()
        pdfContext.closePDF()

        // Save next to input file
        let originalName = docFileURL.deletingPathExtension().lastPathComponent
        let newName = getTimeName(name: originalName)
        let pdfURL = docFileURL.deletingLastPathComponent().appendingPathComponent(newName)
//        let pdfURL = docFileURL.deletingPathExtension().appendingPathExtension("pdf")
        
        let success = pdfData.write(to: pdfURL, atomically: true)
        if success {
            print("✅ PDF saved at: \(pdfURL.path)")
        } else {
            print("❌ Failed to save PDF at: \(pdfURL.path)")
        }
        return success

    } catch {
        print("❌ ERROR executing catdoc: \(error)")
        return false
    }
}
