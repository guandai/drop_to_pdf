import Cocoa
import PDFKit
import CoreText

func convertDocToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            // 1️⃣ Locate `antiword` in the app bundle
            let docBin = Bundle.main.bundlePath + "/Contents/MacOS/antiword"
            guard FileManager.default.fileExists(atPath: docBin) else {
                print("❌ antiword not found at \(docBin)")
                return continuation.resume(returning: false)
            }

            // 2️⃣ Ensure execute permissions
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: docBin)
                if let permissions = attributes[.posixPermissions] as? NSNumber {
                    let permissionValue = permissions.uint16Value
                    if (permissionValue & 0o111) == 0 {
                        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docBin)
                        print("✅ Executable permissions set for antiword")
                    }
                }
            } catch {
                print("❌ Failed to set permissions for antiword: \(error)")
                return continuation.resume(returning: false)
            }

            let task = Process()
            task.executableURL = URL(fileURLWithPath: docBin)
            task.arguments = [fileURL.path]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                let didStart = fileURL.startAccessingSecurityScopedResource()
                defer { if didStart { fileURL.stopAccessingSecurityScopedResource() } }

                try task.run()
                task.waitUntilExit()

                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let extractedText = String(data: outputData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                      !extractedText.isEmpty else {
                    print("❌ Could not extract text from .doc")
                    return continuation.resume(returning: false)
                }

                // ✅ Create PDF properly
                let pdfData = NSMutableData()
                let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
                var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
                let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!

                pdfContext.beginPage(mediaBox: &mediaBox)

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]

                let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
                NSString(string: extractedText).draw(in: textRect, withAttributes: attributes)

                // ✅ Ensure the page is finalized before closing the PDF
                pdfContext.endPage()
                pdfContext.closePDF()

                // ✅ Ensure PDF data is saved correctly
                Task {
                    let success = await saveToPdf(fileURL: fileURL, pdfData: pdfData as Data)
                    continuation.resume(returning: success)
                }

            } catch {
                print("❌ Error running antiword: \(error)")
                return continuation.resume(returning: false)
            }
        }
    }
}
