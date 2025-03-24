import Cocoa

class PrintToPDF {
    func getPrintInfo(_ finalPath: URL) -> NSPrintInfo {
        let margin: CGFloat = 30
        let printInfo = NSPrintInfo()
            printInfo.horizontalPagination = .automatic
            printInfo.verticalPagination = .automatic
            printInfo.paperSize = NSSize(width: 595, height: 842)
            printInfo.topMargin = margin
            printInfo.bottomMargin = margin
            printInfo.leftMargin = margin
            printInfo.rightMargin = margin
            printInfo.isHorizontallyCentered = true
            printInfo.isVerticallyCentered = false
            printInfo.jobDisposition = .save
            printInfo.dictionary()[
                NSPrintInfo.AttributeKey(
                    rawValue: NSPrintInfo.AttributeKey.jobSavingURL.rawValue)] =
                finalPath
        return printInfo
    }
    
    func runOpration(view printView: ContentPrintView, info printInfo: NSPrintInfo) -> Bool {
        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
            operation.showsPrintPanel = false
            operation.showsProgressPanel = false

        let runResult = operation.run()
        print(runResult ? "✅ runResult PDF saved" : "❌ runResult PDF generation failed")
        return runResult
    }
    
    func sanitizeHTML(_ html: String) -> String {
        print(">> run sanitizeHTML for \(html.count)")
        var cleanedHTML = html

        // Step 1: Join broken tags by removing newlines between angle brackets
        cleanedHTML = cleanedHTML.replacingOccurrences(of: "\n", with: " ")

        // Step 2: Remove <script>, <iframe>, <style> tags and their contents
        let patternsToRemove = [
            "<script.*?>[\\s\\S]*?</script>",
            "<iframe.*?>[\\s\\S]*?</iframe>",
            "<style.*?>[\\s\\S]*?</style>"
        ]
        for pattern in patternsToRemove {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            cleanedHTML = regex.stringByReplacingMatches(in: cleanedHTML, range: NSRange(0..<cleanedHTML.utf16.count), withTemplate: "")
        }

        // Step 3: Remove inline styles (style="..." and style='...')
        let inlineStyleRegex = try! NSRegularExpression(pattern: "\\s*style\\s*=\\s*(['\"])[^'\"]*\\1", options: [.caseInsensitive])
        cleanedHTML = inlineStyleRegex.stringByReplacingMatches(in: cleanedHTML, range: NSRange(0..<cleanedHTML.utf16.count), withTemplate: "")

        // Step 4: Remove remote <img> tags (e.g., <img src="http://...">)
        let remoteImgPattern = "<img[^>]*src\\s*=\\s*\"http[^\"]*\"[^>]*>"
        cleanedHTML = cleanedHTML.replacingOccurrences(of: remoteImgPattern, with: "", options: .regularExpression)

        print(">> Finished sanitizeHTML with \(cleanedHTML.count) characters")
        return cleanedHTML
    }
    
    func getHtmlString(_ fileURL: URL) -> String? {
        guard let htmlString = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("❌ Failed to read HTML file as String")
            return nil
        }
        return sanitizeHTML(htmlString)
    }
    
    func getHtmlNSAttributedString(_ fileUrl: URL, _ cleanedHtml: String) -> NSAttributedString? {
        guard let htmlData = cleanedHtml.data(using: .utf8) else {
            print("❌ Failed to convert cleaned HTML string to Data")
            return nil
        }

        let baseURL = fileUrl.deletingLastPathComponent() // 👈 this allows resolving src="docx.fld/..."
        guard let attributed = try? NSAttributedString(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
                .baseURL: baseURL // ✅ key addition
            ],
            documentAttributes: nil
        ) else {
            print("❌ Failed to convert attributed string")
            return nil
        }
        return attributed
    }
    
    func changeHtmlFont(_ attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.addAttribute(.font, value: NSFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: mutable.length))
        return  NSAttributedString(attributedString: mutable)
    }
    
    func getHtmlAttributedText(_ fileURL: URL) -> NSAttributedString? {
        guard let cleanedHtml = getHtmlString(fileURL) else { return nil }
        guard let attributed = getHtmlNSAttributedString(fileURL, cleanedHtml) else { return nil }
        return changeHtmlFont(attributed)
    }
    
    func getAttributedText(fileURL: URL, docType: NSAttributedString.DocumentType) -> NSAttributedString? {
        if docType == .html {
            return getHtmlAttributedText(fileURL)
        }
        
        guard let attributedText = try? NSAttributedString(
            url: fileURL,
            options: [.documentType: docType],
            documentAttributes: nil)
        else {
            print("❌ Failed to load RTFD package from \(fileURL.path)")
            return nil
        }
        return attributedText
    }
    
    func printContentToPDF(finalPath: URL, fileURL: URL, docType: NSAttributedString.DocumentType) async -> Bool {
        let result = await MainActor.run { () -> Bool in
            guard let attributedText = getAttributedText(fileURL: fileURL, docType: docType) else {
                return false
            }

            let printView = ContentPrintView(
                frame: NSRect(x: 0, y: 0, width: 595, height: 842),
                attributedText: attributedText
            )
            print(">> get print view")
            return runOpration(view: printView, info: getPrintInfo(finalPath))
        }
        return result
    }
}
