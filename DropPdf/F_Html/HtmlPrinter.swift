import Cocoa

class HtmlPrinter {
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
    }
