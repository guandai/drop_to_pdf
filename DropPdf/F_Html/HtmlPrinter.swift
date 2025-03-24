import Cocoa

class HtmlPrinter {
    func sanitizeHTML(_ html: String) -> String {
        var cleanedHTML = html

        // Step 1: Join broken tags by removing newlines between angle brackets
        cleanedHTML = cleanedHTML.replacingOccurrences(of: "\n", with: " ")

        // Step 2: Remove <script>, <iframe>, <style> tags and their contents
        var patternsToRemove = [
            "<script.*?>[\\s\\S]*?</script>",
            "<iframe.*?>[\\s\\S]*?</iframe>"
        ]
        for pattern in patternsToRemove {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            cleanedHTML = regex.stringByReplacingMatches(
                in: cleanedHTML,
                range: NSRange(0..<cleanedHTML.utf16.count),
                withTemplate: "")
        }
        
        patternsToRemove = [
            "<link[^>]*src\\s*=\\s*\"href[^\"]*\"[^>]*>",
            "<img[^>]*src\\s*=\\s*\"data:image/[^;]+;base64,[^\"]{1000,}\"[^>]*>",
            "<img[^>]*src\\s*=\\s*\"http[^\"]*\"[^>]*>"
        ]

        for pattern in patternsToRemove {
            cleanedHTML = cleanedHTML.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression)
        }

        return cleanedHTML
    }

    func getHtmlString(_ fileURL: URL) -> String? {
        do {
            var rawEncoding: UInt = 0
            let htmlNSString = try NSString(contentsOf: fileURL, usedEncoding: &rawEncoding)

            // Convert UInt to String.Encoding
            let encoding = String.Encoding(rawValue: rawEncoding)
            print("✅ Detected encoding: \(encoding)")

            let htmlString = String(htmlNSString as String)
            return sanitizeHTML(htmlString)
        } catch {
            print("❌ Failed to read HTML with encoding detection: \(error.localizedDescription)")
            return nil
        }
    }

    func getHtmlNSAttributedString(_ fileUrl: URL, _ cleanedHtml: String)
        -> NSAttributedString?
    {
        guard let htmlData = cleanedHtml.data(using: .utf8) else {
            print("❌ Failed to convert cleaned HTML string to Data")
            return nil
        }

        let baseURL = fileUrl.deletingLastPathComponent()  // 👈 this allows resolving src="docx.fld/..."
        guard
            let attributed = try? NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                    .baseURL: baseURL,  // ✅ key addition
                ],
                documentAttributes: nil
            )
        else {
            print("❌ Failed to convert attributed string")
            return nil
        }
        return attributed
    }

    func attributedStringWithBase64Image(_ base64String: String) -> NSAttributedString? {
        guard let data = Data(base64Encoded: base64String),
              let image = NSImage(data: data) else { return nil }

        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: 0, width: 200, height: 200) // set size as needed

        let attrString = NSAttributedString(attachment: attachment)
        return attrString
    }
    
    func changeHtmlFont(_ attributed: NSAttributedString) -> NSAttributedString
    {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.addAttribute(
            .font, value: NSFont.systemFont(ofSize: 12),
            range: NSRange(location: 0, length: mutable.length))
        return NSAttributedString(attributedString: mutable)
    }

    func getHtmlAttributedText(_ fileURL: URL) -> NSAttributedString? {
        guard let cleanedHtml = getHtmlString(fileURL) else { return nil }
//        let tempFileURL = fileURL.deletingLastPathComponent().appendingPathComponent("temp.html")
//            do {
//                try cleanedHtml.write(to: tempFileURL, atomically: true, encoding: .utf8)
//                print("✅ Cleaned HTML saved to: \(tempFileURL.path)")
//            } catch {
//                print("❌ Failed to write cleaned HTML to file: \(error.localizedDescription)")
//            }
        guard let attributed = getHtmlNSAttributedString(fileURL, cleanedHtml)
        else { return nil }
        return changeHtmlFont(attributed)
    }
}
